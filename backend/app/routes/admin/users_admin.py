from decimal import Decimal
from typing import Annotated
from fastapi import APIRouter, Depends, Path, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_
from sqlalchemy.orm import aliased
from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.security import hash_password
from app.models.user import User, UserVerification
from app.models.referral import Referral
from app.models.wallet import Withdrawal
from app.schemas.user_schema import (
    UserListResponse,
    AdminUserUpdate,
    AdminUserReferralItemResponse,
)
from app.schemas.common_schema import PaginatedResponse
from app.schemas.auth_schema import MessageResponse
from app.services import wallet_service
from app.services import verification_service


router = APIRouter(prefix="/admin/users", tags=["Admin - Users"])
DEFAULT_RESET_PASSWORD = "GoldX@1234"


def _build_admin_user_response(
    user: User,
    wallet_address: str | None,
    referral_count: int,
    referral_total_deposits,
    verification_status: str | None = None,
    verification_submitted_at=None,
    verification_reviewed_at=None,
    verification_rejection_reason: str | None = None,
    verification_id_document_filename: str | None = None,
    verification_selfie_document_filename: str | None = None,
    base_url: str | None = None,
) -> UserListResponse:
    breakdown = wallet_service.build_user_balance_breakdown(user)
    return UserListResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        is_active=user.is_active,
        wallet_balance=breakdown["balance"],
        capital_balance=breakdown["capital_balance"],
        signal_profit_balance=breakdown["signal_profit_balance"],
        reward_balance=breakdown["reward_balance"],
        withdrawable_balance=breakdown["withdrawable_balance"],
        locked_capital_balance=breakdown["locked_capital_balance"],
        capital_lock_active=breakdown["capital_lock_active"],
        capital_lock_ends_at=breakdown["capital_lock_ends_at"],
        capital_lock_days_remaining=breakdown["capital_lock_days_remaining"],
        vip_level=user.vip_level,
        wallet_address=wallet_address,
        referral_count=referral_count,
        referral_total_deposits=referral_total_deposits,
        verification_status=verification_status or "not_submitted",
        verification_submitted_at=verification_submitted_at,
        verification_reviewed_at=verification_reviewed_at,
        verification_rejection_reason=verification_rejection_reason,
        verification_id_document_url=verification_service.build_verification_document_url(
            user.id,
            verification_id_document_filename,
            base_url,
        ),
        verification_selfie_document_url=verification_service.build_verification_document_url(
            user.id,
            verification_selfie_document_filename,
            base_url,
        ),
        verification_address_document_url=verification_service.build_verification_document_url(
            user.id,
            verification_selfie_document_filename,
            base_url,
        ),
        created_at=user.created_at,
    )


@router.get("", response_model=PaginatedResponse[UserListResponse])
async def list_users(
    request: Request,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    role: str = Query(None, pattern="^(user|admin)$"),
    search: str = Query(None),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    List all users (admin only).
    Supports filtering by role and searching by user id, username/full name,
    email, and wallet address.
    """
    referral_agg = (
        select(
            Referral.referrer_id.label("referrer_id"),
            func.count(Referral.id).label("referral_count"),
            func.coalesce(func.sum(Referral.deposit_amount), 0).label(
                "referral_total_deposits"
            ),
        )
        .group_by(Referral.referrer_id)
        .subquery()
    )

    wallet_agg = (
        select(
            Withdrawal.user_id.label("wallet_user_id"),
            func.max(Withdrawal.wallet_address).label("wallet_address"),
        )
        .where(Withdrawal.wallet_address.is_not(None), Withdrawal.wallet_address != "")
        .group_by(Withdrawal.user_id)
        .subquery()
    )

    query = (
        select(
            User,
            func.coalesce(referral_agg.c.referral_count, 0).label("referral_count"),
            func.coalesce(referral_agg.c.referral_total_deposits, 0).label(
                "referral_total_deposits"
            ),
            wallet_agg.c.wallet_address.label("wallet_address"),
            UserVerification.status.label("verification_status"),
            UserVerification.submitted_at.label("verification_submitted_at"),
            UserVerification.reviewed_at.label("verification_reviewed_at"),
            UserVerification.rejection_reason.label("verification_rejection_reason"),
            UserVerification.id_document_filename.label(
                "verification_id_document_filename"
            ),
            UserVerification.address_document_filename.label(
                "verification_selfie_document_filename"
            ),
        )
        .outerjoin(referral_agg, referral_agg.c.referrer_id == User.id)
        .outerjoin(wallet_agg, wallet_agg.c.wallet_user_id == User.id)
        .outerjoin(UserVerification, UserVerification.user_id == User.id)
    )

    count_query = (
        select(func.count(User.id))
        .select_from(User)
        .outerjoin(referral_agg, referral_agg.c.referrer_id == User.id)
        .outerjoin(wallet_agg, wallet_agg.c.wallet_user_id == User.id)
    )

    if role:
        query = query.where(User.role == role)
        count_query = count_query.where(User.role == role)

    if search:
        normalized_search = search.strip()
        if normalized_search:
            search_filter = f"%{normalized_search}%"
            filters = [
                User.email.ilike(search_filter),
                User.full_name.ilike(search_filter),
                wallet_agg.c.wallet_address.ilike(search_filter),
            ]

            if normalized_search.isdigit():
                filters.append(User.id == int(normalized_search))

            query = query.where(or_(*filters))
            count_query = count_query.where(or_(*filters))

    query = query.order_by(User.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    rows = result.all()
    base_url = str(request.base_url).rstrip("/")
    total_result = await db.execute(count_query)
    total = int(total_result.scalar_one() or 0)

    return PaginatedResponse[UserListResponse](
        items=[
            _build_admin_user_response(
                user=row[0],
                wallet_address=row.wallet_address,
                referral_count=int(row.referral_count or 0),
                referral_total_deposits=row.referral_total_deposits,
                verification_status=row.verification_status,
                verification_submitted_at=row.verification_submitted_at,
                verification_reviewed_at=row.verification_reviewed_at,
                verification_rejection_reason=row.verification_rejection_reason,
                verification_id_document_filename=row.verification_id_document_filename,
                verification_selfie_document_filename=row.verification_selfie_document_filename,
                base_url=base_url,
            )
            for row in rows
        ],
        total=total,
        skip=skip,
        limit=limit,
    )


@router.get("/{user_id}", response_model=UserListResponse)
async def get_user(
    request: Request,
    user_id: Annotated[int, Path(ge=1000000, le=9999999)],
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get a specific user's details (admin only)."""
    from fastapi import HTTPException

    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    referral_result = await db.execute(
        select(
            func.count(Referral.id),
            func.coalesce(func.sum(Referral.deposit_amount), 0),
        ).where(Referral.referrer_id == user.id)
    )
    referral_count, referral_total_deposits = referral_result.one()

    wallet_result = await db.execute(
        select(func.max(Withdrawal.wallet_address)).where(
            Withdrawal.user_id == user.id,
            Withdrawal.wallet_address.is_not(None),
            Withdrawal.wallet_address != "",
        )
    )
    wallet_address = wallet_result.scalar_one_or_none()
    verification_result = await db.execute(
        select(UserVerification).where(UserVerification.user_id == user.id)
    )
    verification = verification_result.scalar_one_or_none()
    base_url = str(request.base_url).rstrip("/")

    return _build_admin_user_response(
        user=user,
        wallet_address=wallet_address,
        referral_count=int(referral_count or 0),
        referral_total_deposits=referral_total_deposits,
        verification_status=(
            verification_service.get_verification_status_value(verification)
            if verification
            else "not_submitted"
        ),
        verification_submitted_at=verification.submitted_at if verification else None,
        verification_reviewed_at=verification.reviewed_at if verification else None,
        verification_rejection_reason=(
            verification.rejection_reason if verification else None
        ),
        verification_id_document_filename=(
            verification.id_document_filename if verification else None
        ),
        verification_selfie_document_filename=(
            verification.address_document_filename if verification else None
        ),
        base_url=base_url,
    )


@router.put("/{user_id}", response_model=UserListResponse)
async def update_user(
    request: Request,
    user_id: Annotated[int, Path(ge=1000000, le=9999999)],
    data: AdminUserUpdate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Update a user's details (admin only).
    Can modify: name, phone, active status, VIP level, role, wallet balance.
    """
    from fastapi import HTTPException

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if value is not None:
            setattr(user, key, value)

    if (
        data.wallet_balance is not None
        and data.capital_balance is None
        and data.signal_profit_balance is None
        and data.reward_balance is None
    ):
        signal_profit_balance = Decimal(str(user.signal_profit_balance or 0))
        reward_balance = Decimal(str(user.reward_balance or 0))
        user.capital_balance = max(
            Decimal(str(data.wallet_balance)) - signal_profit_balance - reward_balance,
            Decimal("0"),
        )

    wallet_service.sync_user_total_balance(user)

    await db.flush()

    referral_result = await db.execute(
        select(
            func.count(Referral.id),
            func.coalesce(func.sum(Referral.deposit_amount), 0),
        ).where(Referral.referrer_id == user.id)
    )
    referral_count, referral_total_deposits = referral_result.one()

    wallet_result = await db.execute(
        select(func.max(Withdrawal.wallet_address)).where(
            Withdrawal.user_id == user.id,
            Withdrawal.wallet_address.is_not(None),
            Withdrawal.wallet_address != "",
        )
    )
    wallet_address = wallet_result.scalar_one_or_none()
    verification_result = await db.execute(
        select(UserVerification).where(UserVerification.user_id == user.id)
    )
    verification = verification_result.scalar_one_or_none()
    base_url = str(request.base_url).rstrip("/")

    return _build_admin_user_response(
        user=user,
        wallet_address=wallet_address,
        referral_count=int(referral_count or 0),
        referral_total_deposits=referral_total_deposits,
        verification_status=(
            verification_service.get_verification_status_value(verification)
            if verification
            else "not_submitted"
        ),
        verification_submitted_at=verification.submitted_at if verification else None,
        verification_reviewed_at=verification.reviewed_at if verification else None,
        verification_rejection_reason=(
            verification.rejection_reason if verification else None
        ),
        verification_id_document_filename=(
            verification.id_document_filename if verification else None
        ),
        verification_selfie_document_filename=(
            verification.address_document_filename if verification else None
        ),
        base_url=base_url,
    )


@router.post("/{user_id}/reset-withdrawal-password", response_model=MessageResponse)
async def reset_withdrawal_password(
    user_id: Annotated[int, Path(ge=1000000, le=9999999)],
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Reset a user's withdrawal password to GoldX@1234 (admin only).
    """
    from fastapi import HTTPException

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Hash the default password and set it as the withdrawal password
    user.withdrawal_password_hash = hash_password(DEFAULT_RESET_PASSWORD)

    await db.flush()
    return MessageResponse(message=f"Withdrawal password reset to {DEFAULT_RESET_PASSWORD}")


@router.post("/{user_id}/reset-login-password", response_model=MessageResponse)
async def reset_login_password(
    user_id: Annotated[int, Path(ge=1000000, le=9999999)],
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Reset a user's login password to GoldX@1234 (admin only).
    """
    from fastapi import HTTPException

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.password_hash = hash_password(DEFAULT_RESET_PASSWORD)

    await db.flush()
    return MessageResponse(message=f"Login password reset to {DEFAULT_RESET_PASSWORD}")


@router.delete("/{user_id}", response_model=MessageResponse)
async def delete_user(
    user_id: Annotated[int, Path(ge=1000000, le=9999999)],
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete a user (admin only).
    """
    from fastapi import HTTPException
    from sqlalchemy import delete

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Delete the user
    await db.execute(delete(User).where(User.id == user_id))
    await db.flush()

    return MessageResponse(message="User deleted successfully")


@router.get(
    "/{user_id}/referrals",
    response_model=list[AdminUserReferralItemResponse],
)
async def get_user_referrals(
    user_id: Annotated[int, Path(ge=1000000, le=9999999)],
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get all referrals under a specific user with per-user deposit amounts."""
    from fastapi import HTTPException

    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    referred_user = aliased(User)
    result = await db.execute(
        select(
            Referral.id.label("referral_id"),
            Referral.referred_user_id,
            referred_user.email.label("referred_email"),
            referred_user.full_name.label("referred_full_name"),
            Referral.deposit_amount,
            Referral.bonus_amount,
            Referral.status,
            Referral.created_at,
        )
        .join(referred_user, referred_user.id == Referral.referred_user_id)
        .where(Referral.referrer_id == user_id)
        .order_by(Referral.created_at.desc())
    )

    return [
        AdminUserReferralItemResponse(
            referral_id=row.referral_id,
            referred_user_id=row.referred_user_id,
            referred_email=row.referred_email,
            referred_full_name=row.referred_full_name,
            deposit_amount=row.deposit_amount,
            bonus_amount=row.bonus_amount,
            status=row.status,
            created_at=row.created_at,
        )
        for row in result.all()
    ]
