from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.user import User, UserVerification

ALLOWED_VERIFICATION_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".pdf"}
ALLOWED_VERIFICATION_STATUSES = {
    "not_submitted",
    "pending",
    "approved",
    "rejected",
}


def get_verification_directory(user_id: int) -> Path:
    directory = Path(settings.UPLOADS_DIR).resolve() / "verifications" / str(user_id)
    directory.mkdir(parents=True, exist_ok=True)
    return directory


def get_verification_document_path(user_id: int, filename: str) -> Path:
    return get_verification_directory(user_id) / filename


def build_verification_document_url(
    user_id: int,
    filename: str | None,
    base_url: str | None = None,
) -> str | None:
    if not filename:
        return None

    relative = f"/uploads/verifications/{user_id}/{filename}"
    if not base_url:
        return relative

    return f"{base_url.rstrip('/')}{relative}"


async def _validate_verification_upload(
    upload: UploadFile,
    document_name: str,
) -> tuple[str, bytes]:
    extension = Path(upload.filename or "").suffix.lower() or ".jpg"
    if extension not in ALLOWED_VERIFICATION_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"{document_name} must be one of: "
                ".png, .jpg, .jpeg, .webp, .pdf"
            ),
        )

    content_type = (upload.content_type or "").lower()
    if extension == ".pdf":
        if content_type and content_type not in {"application/pdf", "application/octet-stream"}:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"{document_name} must be a valid PDF file",
            )
    elif content_type and not content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{document_name} must be an image or PDF",
        )

    file_content = await upload.read()
    if not file_content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{document_name} file is empty",
        )

    max_bytes = settings.VERIFICATION_MAX_FILE_SIZE_MB * 1024 * 1024
    if len(file_content) > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=(
                f"{document_name} exceeds {settings.VERIFICATION_MAX_FILE_SIZE_MB}MB"
            ),
        )

    return extension, file_content


async def save_verification_document(
    user_id: int,
    upload: UploadFile,
    document_prefix: str,
) -> str:
    extension, file_content = await _validate_verification_upload(
        upload,
        document_prefix.replace("_", " ").title(),
    )

    filename = f"{document_prefix}_{uuid4().hex}{extension}"
    file_path = get_verification_document_path(user_id, filename)
    file_path.write_bytes(file_content)
    return filename


def delete_verification_document(user_id: int, filename: str | None) -> None:
    if not filename:
        return

    path = get_verification_document_path(user_id, filename)
    if path.exists():
        path.unlink()


def get_verification_status_value(verification: UserVerification | None) -> str:
    if verification is None:
        return "not_submitted"

    normalized = (verification.status or "").strip().lower()
    if normalized not in ALLOWED_VERIFICATION_STATUSES:
        return "not_submitted"

    return normalized


async def get_or_create_verification(
    user_or_id: User | int,
    db: AsyncSession,
) -> UserVerification:
    user_id = user_or_id.id if isinstance(user_or_id, User) else int(user_or_id)

    result = await db.execute(
        select(UserVerification).where(UserVerification.user_id == user_id)
    )
    verification = result.scalar_one_or_none()

    if verification is None:
        verification = UserVerification(
            user_id=user_id,
            status="not_submitted",
        )
        db.add(verification)
        await db.flush()
        return verification

    normalized_status = get_verification_status_value(verification)
    if verification.status != normalized_status:
        verification.status = normalized_status
        await db.flush()

    return verification


async def submit_user_verification(
    user: User,
    id_document: UploadFile,
    selfie_document: UploadFile,
    db: AsyncSession,
) -> UserVerification:
    verification = await get_or_create_verification(user, db)
    status_value = get_verification_status_value(verification)

    if status_value in {"pending", "approved"}:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Verification already {status_value}",
        )

    old_id_document = verification.id_document_filename
    old_selfie_document = verification.address_document_filename

    new_files: list[str] = []
    try:
        id_filename = await save_verification_document(
            user_id=user.id,
            upload=id_document,
            document_prefix="id_document",
        )
        new_files.append(id_filename)

        selfie_filename = await save_verification_document(
            user_id=user.id,
            upload=selfie_document,
            document_prefix="selfie_document",
        )
        new_files.append(selfie_filename)

        now = datetime.now(timezone.utc)
        verification.id_document_filename = id_filename
        verification.address_document_filename = selfie_filename
        verification.status = "pending"
        verification.submitted_at = now
        verification.reviewed_at = None
        verification.reviewed_by_admin_id = None
        verification.rejection_reason = None

        await db.flush()
    except Exception:
        for filename in new_files:
            delete_verification_document(user.id, filename)
        raise

    if old_id_document and old_id_document != verification.id_document_filename:
        delete_verification_document(user.id, old_id_document)
    if old_selfie_document and old_selfie_document != verification.address_document_filename:
        delete_verification_document(user.id, old_selfie_document)

    return verification


async def approve_user_verification(
    user_id: int,
    admin: User,
    db: AsyncSession,
) -> UserVerification:
    verification = await get_or_create_verification(user_id, db)

    if get_verification_status_value(verification) != "pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only pending verification requests can be approved",
        )

    if not verification.id_document_filename or not verification.address_document_filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification documents are missing",
        )

    verification.status = "approved"
    verification.reviewed_at = datetime.now(timezone.utc)
    verification.reviewed_by_admin_id = admin.id
    verification.rejection_reason = None

    await db.flush()
    return verification


async def reject_user_verification(
    user_id: int,
    admin: User,
    rejection_reason: str,
    db: AsyncSession,
) -> UserVerification:
    verification = await get_or_create_verification(user_id, db)

    if get_verification_status_value(verification) != "pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only pending verification requests can be rejected",
        )

    verification.status = "rejected"
    verification.reviewed_at = datetime.now(timezone.utc)
    verification.reviewed_by_admin_id = admin.id
    verification.rejection_reason = rejection_reason.strip()

    await db.flush()
    return verification
