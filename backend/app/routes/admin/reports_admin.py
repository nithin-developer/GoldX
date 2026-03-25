from decimal import Decimal
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import aliased
from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.models.user import User
from app.models.wallet import Deposit, Withdrawal
from app.models.signal import Signal
from app.models.notification import Notification, Announcement, SupportMessage
from app.models.referral import Referral
from app.schemas.notification_schema import (
    ReportResponse,
    CreateNotificationRequest,
    NotificationResponse,
    CreateAnnouncementRequest,
    AnnouncementResponse,
    SupportMessageResponse,
    AdminSupportReplyRequest,
)
from app.schemas.wallet_schema import (
    DepositResponse,
    WithdrawalResponse,
    AdminDepositAction,
    AdminWithdrawalAction,
)
from app.schemas.auth_schema import MessageResponse
from app.services import wallet_service


router = APIRouter(prefix="/admin", tags=["Admin - Reports & Management"])


async def _build_support_chat_payload(db: AsyncSession) -> list[dict]:
    """Build support chats in the shape used by the admin frontend."""
    result = await db.execute(
        select(
            SupportMessage.user_id,
            User.email.label("user_email"),
            func.max(SupportMessage.created_at).label("updated_at"),
        )
        .join(User, User.id == SupportMessage.user_id)
        .group_by(SupportMessage.user_id, User.email)
        .order_by(func.max(SupportMessage.created_at).desc())
    )

    chats = []
    for row in result.all():
        messages_result = await db.execute(
            select(SupportMessage)
            .where(SupportMessage.user_id == row.user_id)
            .order_by(SupportMessage.created_at.asc())
        )
        messages = messages_result.scalars().all()

        chats.append(
            {
                "id": row.user_id,
                "user_id": row.user_id,
                "user_email": row.user_email,
                "updated_at": row.updated_at,
                "messages": [
                    {
                        "id": m.id,
                        "message": m.message,
                        "sender": "admin" if m.sender_type == "admin" else "user",
                        "created_at": m.created_at,
                    }
                    for m in messages
                ],
            }
        )

    return chats


# --- Reports ---
@router.get("/reports", response_model=ReportResponse)
async def get_reports(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get system-wide reports and statistics (admin only)."""
    # Total users
    total_users = (await db.execute(select(func.count(User.id)))).scalar()
    active_users = (
        await db.execute(
            select(func.count(User.id)).where(User.is_active == True)  # noqa: E712
        )
    ).scalar()

    # Deposits
    total_deposits = (
        await db.execute(
            select(func.coalesce(func.sum(Deposit.amount), 0)).where(
                Deposit.status == "approved"
            )
        )
    ).scalar()

    pending_deposits = (
        await db.execute(
            select(func.count(Deposit.id)).where(Deposit.status == "pending")
        )
    ).scalar()

    # Withdrawals
    total_withdrawals = (
        await db.execute(
            select(func.coalesce(func.sum(Withdrawal.amount), 0)).where(
                Withdrawal.status == "approved"
            )
        )
    ).scalar()

    pending_withdrawals = (
        await db.execute(
            select(func.count(Withdrawal.id)).where(Withdrawal.status == "pending")
        )
    ).scalar()

    # Signals
    total_signals = (await db.execute(select(func.count(Signal.id)))).scalar()
    active_signals = (
        await db.execute(
            select(func.count(Signal.id)).where(Signal.status == "active")
        )
    ).scalar()

    # Total wallet balance
    total_balance = (
        await db.execute(select(func.coalesce(func.sum(User.wallet_balance), 0)))
    ).scalar()

    return ReportResponse(
        total_users=total_users,
        active_users=active_users,
        total_deposits=total_deposits,
        total_withdrawals=total_withdrawals,
        pending_deposits=pending_deposits,
        pending_withdrawals=pending_withdrawals,
        total_signals=total_signals,
        active_signals=active_signals,
        total_wallet_balance=total_balance,
    )


# --- Deposit Management ---
@router.get("/deposits", response_model=list[DepositResponse])
async def list_all_deposits(
    status: str = Query(None, pattern="^(pending|approved|rejected)$"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """List all deposits with optional status filter (admin only)."""
    query = select(Deposit)
    if status:
        query = query.where(Deposit.status == status)
    query = query.order_by(Deposit.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    deposits = result.scalars().all()
    return [DepositResponse.model_validate(d) for d in deposits]


@router.put("/deposits/{deposit_id}/approve", response_model=DepositResponse)
async def approve_deposit(
    deposit_id: int,
    data: AdminDepositAction,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Approve a pending deposit and credit user's wallet (admin only)."""
    deposit = await wallet_service.approve_deposit(deposit_id, data.admin_note, db)
    return DepositResponse.model_validate(deposit)


@router.put("/deposits/{deposit_id}/reject", response_model=DepositResponse)
async def reject_deposit(
    deposit_id: int,
    data: AdminDepositAction,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Reject a pending deposit (admin only)."""
    deposit = await wallet_service.reject_deposit(deposit_id, data.admin_note, db)
    return DepositResponse.model_validate(deposit)


# --- Withdrawal Management ---
@router.get("/withdrawals", response_model=list[WithdrawalResponse])
async def list_all_withdrawals(
    status: str = Query(None, pattern="^(pending|approved|rejected)$"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """List all withdrawals with optional status filter (admin only)."""
    query = select(Withdrawal)
    if status:
        query = query.where(Withdrawal.status == status)
    query = query.order_by(Withdrawal.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    withdrawals = result.scalars().all()
    return [WithdrawalResponse.model_validate(w) for w in withdrawals]


@router.put("/withdrawals/{withdrawal_id}/approve", response_model=WithdrawalResponse)
async def approve_withdrawal(
    withdrawal_id: int,
    data: AdminWithdrawalAction,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Approve a pending withdrawal and debit user's wallet (admin only)."""
    withdrawal = await wallet_service.approve_withdrawal(
        withdrawal_id, data.admin_note, db
    )
    return WithdrawalResponse.model_validate(withdrawal)


@router.put("/withdrawals/{withdrawal_id}/reject", response_model=WithdrawalResponse)
async def reject_withdrawal(
    withdrawal_id: int,
    data: AdminWithdrawalAction,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Reject a pending withdrawal (admin only)."""
    withdrawal = await wallet_service.reject_withdrawal(
        withdrawal_id, data.admin_note, db
    )
    return WithdrawalResponse.model_validate(withdrawal)


# --- Notifications ---
@router.post("/notifications", response_model=MessageResponse, status_code=201)
async def send_notification(
    data: CreateNotificationRequest,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Send notification to a specific user or broadcast to all users (admin only).

    - **user_id**: Specific user to notify (null = broadcast)
    - **title**: Notification title
    - **message**: Notification body
    - **type**: system, signal, referral, or support
    """
    if data.user_id:
        # Send to specific user
        notification = Notification(
            user_id=data.user_id,
            title=data.title,
            message=data.message,
            type=data.type,
        )
        db.add(notification)
    else:
        # Broadcast to all active users
        result = await db.execute(
            select(User.id).where(User.is_active == True, User.role == "user")  # noqa: E712
        )
        user_ids = result.scalars().all()
        for uid in user_ids:
            notification = Notification(
                user_id=uid,
                title=data.title,
                message=data.message,
                type=data.type,
            )
            db.add(notification)

    await db.flush()
    return MessageResponse(message="Notification sent successfully")


# --- Announcements ---
@router.get("/announcements", response_model=list[AnnouncementResponse])
async def list_announcements(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """List all announcements (admin only)."""
    result = await db.execute(
        select(Announcement).order_by(Announcement.created_at.desc())
    )
    announcements = result.scalars().all()
    return [AnnouncementResponse.model_validate(a) for a in announcements]


@router.post("/announcements", response_model=AnnouncementResponse, status_code=201)
async def create_announcement(
    data: CreateAnnouncementRequest,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Create a new announcement (admin only)."""
    announcement = Announcement(
        title=data.title,
        message=data.message,
        start_date=data.start_date,
        end_date=data.end_date,
    )
    db.add(announcement)
    await db.flush()
    return AnnouncementResponse.model_validate(announcement)


# --- Referrals / VIP (Admin UI compatibility) ---
@router.get("/referrals", response_model=list[dict])
async def list_referrals_admin(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """List all referral records for the admin referrals page."""
    referrer_user = aliased(User)
    referred_user = aliased(User)

    result = await db.execute(
        select(
            Referral.id,
            referrer_user.email.label("referrer_email"),
            referred_user.email.label("referred_email"),
            Referral.deposit_amount,
            Referral.status,
        )
        .join(referrer_user, Referral.referrer_id == referrer_user.id)
        .join(referred_user, Referral.referred_user_id == referred_user.id)
        .order_by(Referral.created_at.desc())
    )

    return [
        {
            "id": row.id,
            "referrer": row.referrer_email,
            "referred_user": row.referred_email,
            "deposit": float(row.deposit_amount or Decimal("0")),
            "status": row.status,
        }
        for row in result.all()
    ]


@router.get("/vip-users", response_model=list[dict])
async def list_vip_users_admin(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """List VIP users for the admin VIP page."""
    referral_count_subquery = (
        select(
            Referral.referrer_id.label("referrer_id"),
            func.count(Referral.id).label("referrals_count"),
        )
        .group_by(Referral.referrer_id)
        .subquery()
    )

    result = await db.execute(
        select(
            User.id,
            User.email,
            User.vip_level,
            func.coalesce(referral_count_subquery.c.referrals_count, 0).label(
                "referrals_count"
            ),
        )
        .outerjoin(referral_count_subquery, referral_count_subquery.c.referrer_id == User.id)
        .where(User.role == "user", User.vip_level > 0)
        .order_by(User.vip_level.desc(), User.created_at.desc())
    )

    return [
        {
            "id": row.id,
            "email": row.email,
            "vip_level": row.vip_level,
            "referrals_count": row.referrals_count,
        }
        for row in result.all()
    ]


# --- Support Chat ---
@router.get("/support", response_model=list[dict])
async def list_support_chats_ui(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """UI-friendly support endpoint used by the current admin frontend."""
    return await _build_support_chat_payload(db)


@router.get("/support/chats", response_model=list[dict])
async def list_support_chats(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """List all unique support chat users with their latest message (admin only)."""
    # Get distinct user IDs who have support messages
    result = await db.execute(
        select(
            SupportMessage.user_id,
            func.max(SupportMessage.created_at).label("last_message_at"),
            func.count(SupportMessage.id).label("message_count"),
        )
        .group_by(SupportMessage.user_id)
        .order_by(func.max(SupportMessage.created_at).desc())
    )
    rows = result.all()

    chats = []
    for row in rows:
        # Get user info
        user_result = await db.execute(
            select(User.email, User.full_name).where(User.id == row.user_id)
        )
        user_info = user_result.one_or_none()

        chats.append({
            "user_id": row.user_id,
            "email": user_info.email if user_info else "Unknown",
            "full_name": user_info.full_name if user_info else None,
            "last_message_at": row.last_message_at,
            "message_count": row.message_count,
        })

    return chats


@router.get("/support/messages/{user_id}", response_model=list[SupportMessageResponse])
async def get_user_support_messages(
    user_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get support messages for a specific user (admin only)."""
    result = await db.execute(
        select(SupportMessage)
        .where(SupportMessage.user_id == user_id)
        .order_by(SupportMessage.created_at.asc())
        .offset(skip)
        .limit(limit)
    )
    messages = result.scalars().all()
    return [SupportMessageResponse.model_validate(m) for m in messages]


@router.post("/support/reply", response_model=SupportMessageResponse, status_code=201)
async def reply_to_support(
    data: AdminSupportReplyRequest,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Reply to a user's support message (admin only)."""
    user_id = data.user_id
    message = SupportMessage(
        user_id=user_id,
        sender_type="admin",
        message=data.message,
    )
    db.add(message)

    # Also create a notification for the user
    notification = Notification(
        user_id=user_id,
        title="Support Reply",
        message="You have a new reply from support.",
        type="support",
    )
    db.add(notification)

    await db.flush()
    return SupportMessageResponse.model_validate(message)
