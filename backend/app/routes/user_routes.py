from decimal import Decimal
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.signal import UserSignalEntry
from app.models.referral import Referral
from app.models.notification import Announcement
from app.schemas.user_schema import (
    UserProfileResponse,
    UpdateProfileRequest,
    DashboardResponse,
)
from app.schemas.auth_schema import MessageResponse
from datetime import datetime, timezone


router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/profile", response_model=UserProfileResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    """Get the current user's full profile."""
    return UserProfileResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        role=current_user.role,
        is_active=current_user.is_active,
        invite_code=current_user.invite_code,
        wallet_balance=current_user.wallet_balance,
        vip_level=current_user.vip_level,
        has_withdrawal_password=current_user.withdrawal_password_hash is not None,
        created_at=current_user.created_at,
    )


@router.put("/update", response_model=UserProfileResponse)
async def update_profile(
    data: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update the current user's profile (name, phone)."""
    if data.full_name is not None:
        current_user.full_name = data.full_name
    if data.phone is not None:
        current_user.phone = data.phone

    await db.flush()

    return UserProfileResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        role=current_user.role,
        is_active=current_user.is_active,
        invite_code=current_user.invite_code,
        wallet_balance=current_user.wallet_balance,
        vip_level=current_user.vip_level,
        has_withdrawal_password=current_user.withdrawal_password_hash is not None,
        created_at=current_user.created_at,
    )


# --- Dashboard endpoint ---
dashboard_router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@dashboard_router.get("", response_model=DashboardResponse)
async def get_dashboard(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get dashboard summary including:
    - Wallet balance
    - Active signals count
    - Total profit earned
    - VIP level
    - Total referrals
    - Active announcements
    """
    # Active signals for user
    active_signals_result = await db.execute(
        select(func.count(UserSignalEntry.id)).where(
            UserSignalEntry.user_id == current_user.id,
            UserSignalEntry.status == "active",
        )
    )
    active_signals = active_signals_result.scalar()

    # Total profit
    total_profit_result = await db.execute(
        select(func.coalesce(func.sum(UserSignalEntry.profit_amount), 0)).where(
            UserSignalEntry.user_id == current_user.id,
            UserSignalEntry.status == "completed",
        )
    )
    total_profit = total_profit_result.scalar()

    # Total referrals
    referral_count_result = await db.execute(
        select(func.count(Referral.id)).where(
            Referral.referrer_id == current_user.id
        )
    )
    total_referrals = referral_count_result.scalar()

    # Active announcements
    now = datetime.now(timezone.utc)
    announcements_result = await db.execute(
        select(Announcement).where(
            Announcement.is_active == True,  # noqa: E712
            (Announcement.start_date == None) | (Announcement.start_date <= now),  # noqa: E711
            (Announcement.end_date == None) | (Announcement.end_date >= now),  # noqa: E711
        )
    )
    announcements = announcements_result.scalars().all()

    announcement_list = [
        {"id": a.id, "title": a.title, "message": a.message}
        for a in announcements
    ]

    return DashboardResponse(
        balance=current_user.wallet_balance,
        active_signals=active_signals,
        total_profit=total_profit or Decimal("0"),
        vip_level=current_user.vip_level,
        total_referrals=total_referrals,
        announcements=announcement_list,
    )
