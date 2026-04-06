from decimal import Decimal
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import aliased
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.signal import Signal, UserSignalEntry
from app.models.referral import Referral
from app.models.notification import Announcement
from app.models.wallet import Deposit, WalletTransaction, Withdrawal
from app.schemas.user_schema import (
    HomeDashboardResponse,
    HomeRecentActivityResponse,
    UserProfileResponse,
    UpdateProfileRequest,
    DashboardResponse,
)
from app.services import wallet_service


router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/profile", response_model=UserProfileResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    """Get the current user's full profile."""
    balance_breakdown = wallet_service.build_user_balance_breakdown(current_user)

    return UserProfileResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        role=current_user.role,
        is_active=current_user.is_active,
        invite_code=current_user.invite_code,
        wallet_balance=balance_breakdown["balance"],
        capital_balance=balance_breakdown["capital_balance"],
        signal_profit_balance=balance_breakdown["signal_profit_balance"],
        reward_balance=balance_breakdown["reward_balance"],
        withdrawable_balance=balance_breakdown["withdrawable_balance"],
        locked_capital_balance=balance_breakdown["locked_capital_balance"],
        capital_lock_active=balance_breakdown["capital_lock_active"],
        capital_lock_ends_at=balance_breakdown["capital_lock_ends_at"],
        capital_lock_days_remaining=balance_breakdown["capital_lock_days_remaining"],
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

    balance_breakdown = wallet_service.build_user_balance_breakdown(current_user)

    return UserProfileResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        role=current_user.role,
        is_active=current_user.is_active,
        invite_code=current_user.invite_code,
        wallet_balance=balance_breakdown["balance"],
        capital_balance=balance_breakdown["capital_balance"],
        signal_profit_balance=balance_breakdown["signal_profit_balance"],
        reward_balance=balance_breakdown["reward_balance"],
        withdrawable_balance=balance_breakdown["withdrawable_balance"],
        locked_capital_balance=balance_breakdown["locked_capital_balance"],
        capital_lock_active=balance_breakdown["capital_lock_active"],
        capital_lock_ends_at=balance_breakdown["capital_lock_ends_at"],
        capital_lock_days_remaining=balance_breakdown["capital_lock_days_remaining"],
        vip_level=current_user.vip_level,
        has_withdrawal_password=current_user.withdrawal_password_hash is not None,
        created_at=current_user.created_at,
    )


# --- Dashboard endpoint ---
dashboard_router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


async def _build_dashboard_summary(current_user: User, db: AsyncSession) -> dict:
    # Active signals for user.
    active_signals_result = await db.execute(
        select(func.count(UserSignalEntry.id)).where(
            UserSignalEntry.user_id == current_user.id,
            UserSignalEntry.status == "active",
        )
    )
    active_signals = active_signals_result.scalar() or 0

    # Total profit from completed signals.
    total_profit_result = await db.execute(
        select(func.coalesce(func.sum(UserSignalEntry.profit_amount), 0)).where(
            UserSignalEntry.user_id == current_user.id,
            UserSignalEntry.status == "completed",
        )
    )
    total_profit = total_profit_result.scalar() or Decimal("0")

    # Today's realized signal profit from wallet transactions.
    now = datetime.now(timezone.utc)
    day_start = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)
    today_profit_result = await db.execute(
        select(func.coalesce(func.sum(WalletTransaction.amount), 0)).where(
            WalletTransaction.user_id == current_user.id,
            WalletTransaction.type == "signal_profit",
            WalletTransaction.created_at >= day_start,
        )
    )
    today_profit = today_profit_result.scalar() or Decimal("0")

    # Total referrals.
    referral_count_result = await db.execute(
        select(func.count(Referral.id)).where(Referral.referrer_id == current_user.id)
    )
    total_referrals = referral_count_result.scalar() or 0

    # Active announcements.
    announcements_result = await db.execute(
        select(Announcement).where(
            Announcement.is_active == True,  # noqa: E712
            (Announcement.start_date == None) | (Announcement.start_date <= now),  # noqa: E711
            (Announcement.end_date == None) | (Announcement.end_date >= now),  # noqa: E711
        )
    )
    announcements = announcements_result.scalars().all()

    announcement_list = [
        {"id": a.id, "title": a.title, "message": a.message} for a in announcements
    ]

    active_signal_result = await db.execute(
        select(
            Signal.asset,
            Signal.direction,
            Signal.profit_percent,
            Signal.duration_hours,
            Signal.created_at,
        )
        .where(Signal.status == "active")
        .order_by(Signal.created_at.desc())
        .limit(5)
    )
    active_signal_alerts: list[str] = []
    for row in active_signal_result.all():
        asset = (row.asset or "Signal").upper()
        direction = (row.direction or "").upper()
        if row.profit_percent is not None and row.duration_hours:
            active_signal_alerts.append(
                f"New {asset} {direction} signal live: target +{row.profit_percent:.2f}% in {row.duration_hours}h"
            )
        else:
            active_signal_alerts.append(f"New active signal live for {asset}")

    balance_breakdown = wallet_service.build_user_balance_breakdown(current_user)

    return {
        "balance": balance_breakdown["balance"],
        "capital_balance": balance_breakdown["capital_balance"],
        "signal_profit_balance": balance_breakdown["signal_profit_balance"],
        "reward_balance": balance_breakdown["reward_balance"],
        "withdrawable_balance": balance_breakdown["withdrawable_balance"],
        "locked_capital_balance": balance_breakdown["locked_capital_balance"],
        "capital_lock_active": balance_breakdown["capital_lock_active"],
        "capital_lock_ends_at": balance_breakdown["capital_lock_ends_at"],
        "capital_lock_days_remaining": balance_breakdown["capital_lock_days_remaining"],
        "active_signals": active_signals,
        "total_profit": total_profit,
        "today_profit": today_profit,
        "vip_level": current_user.vip_level,
        "total_referrals": total_referrals,
        "announcements": announcement_list,
        "active_signal_alerts": active_signal_alerts,
    }


async def _build_recent_activities(
    current_user: User,
    db: AsyncSession,
    limit: int,
) -> list[HomeRecentActivityResponse]:
    fetch_limit = max(limit * 3, 20)
    activities: list[HomeRecentActivityResponse] = []

    deposits_result = await db.execute(
        select(Deposit)
        .where(Deposit.user_id == current_user.id)
        .order_by(Deposit.created_at.desc())
        .limit(fetch_limit)
    )
    deposits = deposits_result.scalars().all()

    for deposit in deposits:
        ref_text = (
            f"Reference: {deposit.transaction_ref}"
            if deposit.transaction_ref
            else "Awaiting admin review"
        )
        activities.append(
            HomeRecentActivityResponse(
                id=f"deposit:{deposit.public_id}:requested",
                type="deposit_requested",
                title="Deposit Request Submitted",
                subtitle=ref_text,
                amount=deposit.amount,
                is_positive=None,
                tag="DEPOSIT",
                created_at=deposit.created_at,
            )
        )

        if deposit.status in {"approved", "rejected"}:
            activities.append(
                HomeRecentActivityResponse(
                    id=f"deposit:{deposit.public_id}:{deposit.status}",
                    type=f"deposit_{deposit.status}",
                    title=(
                        "Deposit Approved"
                        if deposit.status == "approved"
                        else "Deposit Rejected"
                    ),
                    subtitle=(
                        deposit.admin_note
                        or (
                            "Funds were credited to your wallet"
                            if deposit.status == "approved"
                            else "Request was rejected by admin"
                        )
                    ),
                    amount=deposit.amount,
                    is_positive=(deposit.status == "approved"),
                    tag=deposit.status.upper(),
                    created_at=deposit.updated_at or deposit.created_at,
                )
            )

    withdrawals_result = await db.execute(
        select(Withdrawal)
        .where(Withdrawal.user_id == current_user.id)
        .order_by(Withdrawal.created_at.desc())
        .limit(fetch_limit)
    )
    withdrawals = withdrawals_result.scalars().all()

    for withdrawal in withdrawals:
        activities.append(
            HomeRecentActivityResponse(
                id=f"withdrawal:{withdrawal.public_id}:requested",
                type="withdrawal_requested",
                title="Withdrawal Request Submitted",
                subtitle=(
                    f"Destination: {withdrawal.wallet_address}"
                    if withdrawal.wallet_address
                    else "Awaiting admin approval"
                ),
                amount=withdrawal.amount,
                is_positive=None,
                tag="WITHDRAW",
                created_at=withdrawal.created_at,
            )
        )

        if withdrawal.status in {"approved", "rejected"}:
            activities.append(
                HomeRecentActivityResponse(
                    id=f"withdrawal:{withdrawal.public_id}:{withdrawal.status}",
                    type=f"withdrawal_{withdrawal.status}",
                    title=(
                        "Withdrawal Approved"
                        if withdrawal.status == "approved"
                        else "Withdrawal Rejected"
                    ),
                    subtitle=(
                        withdrawal.admin_note
                        or (
                            "Funds were debited from your wallet"
                            if withdrawal.status == "approved"
                            else "Request was rejected by admin"
                        )
                    ),
                    amount=withdrawal.amount,
                    is_positive=False,
                    tag=withdrawal.status.upper(),
                    created_at=withdrawal.updated_at or withdrawal.created_at,
                )
            )

    signal_entries_result = await db.execute(
        select(UserSignalEntry, Signal.asset)
        .join(Signal, Signal.id == UserSignalEntry.signal_id)
        .where(UserSignalEntry.user_id == current_user.id)
        .order_by(UserSignalEntry.started_at.desc())
        .limit(fetch_limit)
    )
    for entry, asset in signal_entries_result.all():
        label = (asset or "Signal").upper()
        profit_amount: Decimal | None = None
        if entry.participation_amount is not None and entry.profit_percent is not None:
            participation = Decimal(str(entry.participation_amount))
            percent = Decimal(str(entry.profit_percent))
            profit_amount = (participation * percent) / Decimal("100")

        activities.append(
            HomeRecentActivityResponse(
                id=f"signal:{entry.id}:activated",
                type="signal_activated",
                title=f"Signal Activated: {label}",
                subtitle=(
                    f"Target +{entry.profit_percent:.2f}% before expiry"
                ),
                amount=(
                    profit_amount
                    if profit_amount is not None
                    else entry.participation_amount
                ),
                is_positive=True,
                tag="SIGNAL",
                created_at=entry.started_at,
            )
        )

    referred_user = aliased(User)
    referrals_result = await db.execute(
        select(Referral, referred_user.email)
        .join(referred_user, referred_user.id == Referral.referred_user_id)
        .where(Referral.referrer_id == current_user.id)
        .order_by(Referral.created_at.desc())
        .limit(fetch_limit)
    )
    for referral, referred_email in referrals_result.all():
        status = (referral.status or "pending").lower()
        referred_label = referred_email or f"User #{referral.referred_user_id}"

        if status == "rewarded":
            title = f"Referral Rewarded: {referred_label}"
            subtitle = "Referral bonus has been credited"
            amount = referral.bonus_amount
            is_positive = True
            tag = "REWARD"
            activity_type = "referral_rewarded"
        elif status == "qualified":
            title = f"Referral Qualified: {referred_label}"
            subtitle = "Deposit requirement completed"
            amount = referral.deposit_amount
            is_positive = True
            tag = "QUALIFIED"
            activity_type = "referral_qualified"
        else:
            title = f"Referral Joined: {referred_label}"
            subtitle = "Awaiting qualifying deposit"
            amount = None
            is_positive = None
            tag = "REFERRAL"
            activity_type = "referral_joined"

        activities.append(
            HomeRecentActivityResponse(
                id=f"referral:{referral.id}:{status}",
                type=activity_type,
                title=title,
                subtitle=subtitle,
                amount=amount,
                is_positive=is_positive,
                tag=tag,
                created_at=referral.created_at,
            )
        )

    activities.sort(key=lambda item: item.created_at, reverse=True)
    return activities[:limit]


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
    summary = await _build_dashboard_summary(current_user, db)

    return DashboardResponse(
        balance=summary["balance"],
        capital_balance=summary["capital_balance"],
        signal_profit_balance=summary["signal_profit_balance"],
        reward_balance=summary["reward_balance"],
        withdrawable_balance=summary["withdrawable_balance"],
        locked_capital_balance=summary["locked_capital_balance"],
        capital_lock_active=summary["capital_lock_active"],
        capital_lock_ends_at=summary["capital_lock_ends_at"],
        capital_lock_days_remaining=summary["capital_lock_days_remaining"],
        active_signals=summary["active_signals"],
        total_profit=summary["total_profit"],
        vip_level=summary["vip_level"],
        total_referrals=summary["total_referrals"],
        announcements=summary["announcements"],
    )


@dashboard_router.get("/home", response_model=HomeDashboardResponse)
async def get_home_dashboard(
    activity_limit: int = Query(5, ge=1, le=20),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get home dashboard payload including summary metrics and recent activity feed.

    Recent activity includes deposit/withdraw requests and outcomes,
    signal activations, and referral lifecycle events.
    """
    summary = await _build_dashboard_summary(current_user, db)
    recent_activities = await _build_recent_activities(current_user, db, activity_limit)

    return HomeDashboardResponse(
        balance=summary["balance"],
        capital_balance=summary["capital_balance"],
        signal_profit_balance=summary["signal_profit_balance"],
        reward_balance=summary["reward_balance"],
        withdrawable_balance=summary["withdrawable_balance"],
        locked_capital_balance=summary["locked_capital_balance"],
        capital_lock_active=summary["capital_lock_active"],
        capital_lock_ends_at=summary["capital_lock_ends_at"],
        capital_lock_days_remaining=summary["capital_lock_days_remaining"],
        today_profit=summary["today_profit"],
        total_profit=summary["total_profit"],
        active_signals=summary["active_signals"],
        vip_level=summary["vip_level"],
        total_referrals=summary["total_referrals"],
        announcements=summary["announcements"],
        active_signal_alerts=summary["active_signal_alerts"],
        recent_activities=recent_activities,
    )
