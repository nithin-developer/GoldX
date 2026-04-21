from decimal import Decimal, ROUND_HALF_UP

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.referral import Referral
from app.models.user import User


MIN_QUALIFYING_DEPOSIT = Decimal("500.00")
QUALIFIED_REFERRAL_STATUSES = ("qualified", "rewarded")

VIP_LEVEL_REQUIREMENTS = {
    1: 5,
    2: 10,
    3: 20,
    4: 30,
    5: 40,
    6: 50,
}

TEAM_PROFIT_RATES_PERCENT = {
    1: Decimal("0.5"),
    2: Decimal("0.6"),
    3: Decimal("0.7"),
    4: Decimal("2.0"),
    5: Decimal("4.0"),
    6: Decimal("6.0"),
}

_MONEY_QUANTIZER = Decimal("0.01")
_NORMALIZABLE_REFERRAL_STATUSES = ("pending", "qualified")


def _to_decimal(value: Decimal | int | float | str | None) -> Decimal:
    if value is None:
        return Decimal("0")
    return Decimal(str(value))


def quantize_money(value: Decimal | int | float | str | None) -> Decimal:
    return _to_decimal(value).quantize(_MONEY_QUANTIZER, rounding=ROUND_HALF_UP)


def get_vip_level_for_qualified_referrals(qualified_referrals: int) -> int:
    safe_count = max(int(qualified_referrals or 0), 0)
    for level, min_referrals in sorted(VIP_LEVEL_REQUIREMENTS.items(), reverse=True):
        if safe_count >= min_referrals:
            return level
    return 0


def get_team_profit_rate_percent(vip_level: int) -> Decimal:
    return TEAM_PROFIT_RATES_PERCENT.get(int(vip_level or 0), Decimal("0"))


def calculate_team_profit_amount(trade_profit: Decimal, vip_level: int) -> Decimal:
    normalized_profit = _to_decimal(trade_profit)
    if normalized_profit <= 0:
        return Decimal("0.00")

    rate_percent = get_team_profit_rate_percent(vip_level)
    if rate_percent <= 0:
        return Decimal("0.00")

    return quantize_money((normalized_profit * rate_percent) / Decimal("100"))


def get_next_vip_level(vip_level: int) -> int | None:
    current_level = max(int(vip_level or 0), 0)
    for level in sorted(VIP_LEVEL_REQUIREMENTS.keys()):
        if level > current_level:
            return level
    return None


def get_next_vip_referral_target(vip_level: int) -> int | None:
    next_level = get_next_vip_level(vip_level)
    if next_level is None:
        return None
    return VIP_LEVEL_REQUIREMENTS[next_level]


def get_referrals_needed_for_next_level(qualified_referrals: int, vip_level: int) -> int:
    target = get_next_vip_referral_target(vip_level)
    if target is None:
        return 0
    return max(target - max(int(qualified_referrals or 0), 0), 0)


def sync_referral_status_from_deposit(referral: Referral) -> None:
    # Keep rewarded status once team profit has been paid; otherwise enforce threshold.
    if (referral.status or "").lower() == "rewarded":
        return

    qualifies = _to_decimal(referral.deposit_amount) >= MIN_QUALIFYING_DEPOSIT
    referral.status = "qualified" if qualifies else "pending"


async def count_qualified_referrals(session: AsyncSession, referrer_id: int) -> int:
    result = await session.execute(
        select(func.count(Referral.id)).where(
            Referral.referrer_id == referrer_id,
            Referral.deposit_amount >= MIN_QUALIFYING_DEPOSIT,
            Referral.status.in_(QUALIFIED_REFERRAL_STATUSES),
        )
    )
    return int(result.scalar() or 0)


async def recalculate_user_vip_level(session: AsyncSession, user: User) -> int:
    qualified_referrals = await count_qualified_referrals(session, user.id)
    new_level = get_vip_level_for_qualified_referrals(qualified_referrals)
    user.vip_level = new_level
    return new_level


async def recalculate_vip_for_all_active_users(session: AsyncSession) -> int:
    users = (
        await session.execute(
            select(User).where(User.role == "user", User.is_active.is_(True))
        )
    ).scalars().all()

    updated = 0
    for user in users:
        previous_level = int(user.vip_level or 0)
        new_level = await recalculate_user_vip_level(session, user)
        if previous_level != new_level:
            updated += 1

    return updated


async def normalize_referral_qualification_statuses(session: AsyncSession) -> int:
    referrals = (
        await session.execute(
            select(Referral).where(Referral.status.in_(_NORMALIZABLE_REFERRAL_STATUSES))
        )
    ).scalars().all()

    updated = 0
    for referral in referrals:
        previous_status = (referral.status or "pending").lower()
        sync_referral_status_from_deposit(referral)
        if previous_status != referral.status:
            updated += 1

    return updated


async def normalize_referrals_and_recalculate_vip(session: AsyncSession) -> tuple[int, int]:
    referral_updates = await normalize_referral_qualification_statuses(session)
    vip_updates = await recalculate_vip_for_all_active_users(session)
    return referral_updates, vip_updates