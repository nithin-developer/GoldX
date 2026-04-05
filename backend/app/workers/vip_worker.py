# app/workers/vip_worker.py

import asyncio
import logging
from sqlalchemy import select, func

from app.core.database import async_session_factory
from app.models.user import User
from app.models.referral import Referral

logger = logging.getLogger(__name__)

VIP_LEVELS = {
    1: {"min_referrals": 5, "min_deposit": 500},
    2: {"min_referrals": 10, "min_deposit": 1000},
    3: {"min_referrals": 25, "min_deposit": 5000},
}


async def run_vip_validation():
    async with async_session_factory() as session:
        try:
            users = (
                await session.execute(
                    select(User).where(User.role == "user", User.is_active == True)
                )
            ).scalars().all()

            updated = 0

            for user in users:
                new_vip = 0

                for level in sorted(VIP_LEVELS.keys(), reverse=True):
                    config = VIP_LEVELS[level]

                    result = await session.execute(
                        select(func.count(Referral.id)).where(
                            Referral.referrer_id == user.id,
                            Referral.deposit_amount >= config["min_deposit"],
                            Referral.status.in_(["qualified", "rewarded"]),
                        )
                    )

                    count = result.scalar()

                    if count >= config["min_referrals"]:
                        new_vip = level
                        break

                if user.vip_level != new_vip:
                    user.vip_level = new_vip
                    updated += 1

            await session.commit()

            if updated > 0:
                logger.info(f"Updated {updated} VIP levels")

        except Exception as e:
            await session.rollback()
            logger.error(f"VIP worker error: {e}")
            raise