from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.notification_schema import (
    ReferralResponse,
    ReferralStatsResponse,
)
from app.services import referral_service


router = APIRouter(prefix="/referrals", tags=["Referrals"])


@router.get("", response_model=list[ReferralResponse])
async def get_referrals(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get list of users referred by the current user."""
    referrals = await referral_service.get_user_referrals(current_user, db, skip, limit)
    return [ReferralResponse(**r) for r in referrals]


@router.get("/stats", response_model=ReferralStatsResponse)
async def get_referral_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get referral statistics:
    - Total referrals count
    - Qualified referrals (with deposits)
    - Total bonus earned
    - Your invite code for sharing
    """
    stats = await referral_service.get_referral_stats(current_user, db)
    return ReferralStatsResponse(**stats)
