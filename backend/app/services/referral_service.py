from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.referral import Referral
from app.models.user import User


async def get_user_referrals(
    user: User, db: AsyncSession, skip: int = 0, limit: int = 50
) -> list[dict]:
    """Get list of users referred by the current user."""
    result = await db.execute(
        select(Referral)
        .where(Referral.referrer_id == user.id)
        .order_by(Referral.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    referrals = result.scalars().all()

    enriched = []
    for ref in referrals:
        # Get referred user email
        user_result = await db.execute(
            select(User.email).where(User.id == ref.referred_user_id)
        )
        email = user_result.scalar_one_or_none()

        enriched.append({
            "id": ref.id,
            "referrer_id": ref.referrer_id,
            "referred_user_id": ref.referred_user_id,
            "referred_email": email,
            "deposit_amount": ref.deposit_amount,
            "bonus_amount": ref.bonus_amount,
            "status": ref.status,
            "created_at": ref.created_at,
        })

    return enriched


async def get_referral_stats(user: User, db: AsyncSession) -> dict:
    """Get referral statistics for the current user."""
    # Total referrals
    total_result = await db.execute(
        select(func.count(Referral.id)).where(Referral.referrer_id == user.id)
    )
    total_referrals = total_result.scalar()

    # Qualified referrals
    qualified_result = await db.execute(
        select(func.count(Referral.id)).where(
            Referral.referrer_id == user.id,
            Referral.status.in_(["qualified", "rewarded"]),
        )
    )
    qualified_referrals = qualified_result.scalar()

    # Total bonus earned
    bonus_result = await db.execute(
        select(func.coalesce(func.sum(Referral.bonus_amount), 0)).where(
            Referral.referrer_id == user.id
        )
    )
    total_bonus = bonus_result.scalar()

    return {
        "total_referrals": total_referrals,
        "qualified_referrals": qualified_referrals,
        "total_bonus_earned": total_bonus,
        "invite_code": user.invite_code,
    }
