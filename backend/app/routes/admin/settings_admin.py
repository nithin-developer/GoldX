from fastapi import APIRouter, Depends, File, Form, Request, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.models.user import User
from app.schemas.wallet_schema import DepositSettingsResponse
from app.services import wallet_service


router = APIRouter(prefix="/admin/settings", tags=["Admin - Settings"])


@router.get("/deposit", response_model=DepositSettingsResponse)
async def get_deposit_settings(
    request: Request,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get current deposit wallet settings (admin only)."""
    settings_data = await wallet_service.get_or_create_deposit_settings(db)
    base_url = str(request.base_url).rstrip("/")

    return DepositSettingsResponse(
        currency=settings_data.currency,
        network=settings_data.network,
        wallet_address=settings_data.wallet_address,
        instructions=settings_data.instructions,
        support_url=settings_data.support_url,
        qr_code_url=wallet_service.build_qr_code_url(
            settings_data.qr_code_filename,
            base_url,
        ),
        updated_at=settings_data.updated_at,
    )


@router.put("/deposit", response_model=DepositSettingsResponse)
async def update_deposit_settings(
    request: Request,
    currency: str = Form("USDT"),
    network: str | None = Form(None),
    wallet_address: str | None = Form(None),
    instructions: str | None = Form(None),
    support_url: str | None = Form(None),
    qr_code: UploadFile | None = File(None),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Update deposit wallet address/details and optionally upload a QR code image."""
    settings_data = await wallet_service.update_deposit_settings(
        db=db,
        currency=currency,
        network=network,
        wallet_address=wallet_address,
        instructions=instructions,
        support_url=support_url,
        qr_code=qr_code,
    )

    base_url = str(request.base_url).rstrip("/")
    return DepositSettingsResponse(
        currency=settings_data.currency,
        network=settings_data.network,
        wallet_address=settings_data.wallet_address,
        instructions=settings_data.instructions,
        support_url=settings_data.support_url,
        qr_code_url=wallet_service.build_qr_code_url(
            settings_data.qr_code_filename,
            base_url,
        ),
        updated_at=settings_data.updated_at,
    )
