from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from app.core.database import get_db
from app.core.dependencies import get_verified_user
from app.models.user import User
from app.models.notification import Notification
from app.schemas.notification_schema import (
    NotificationResponse,
    MarkNotificationsReadRequest,
)
from app.schemas.auth_schema import MessageResponse


router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=list[NotificationResponse])
async def get_notifications(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    unread_only: bool = Query(False),
    current_user: User = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """Get notifications for the current user."""
    query = select(Notification).where(Notification.user_id == current_user.id)

    if unread_only:
        query = query.where(Notification.is_read == False)  # noqa: E712

    query = query.order_by(Notification.created_at.desc()).offset(skip).limit(limit)

    result = await db.execute(query)
    notifications = result.scalars().all()
    return [NotificationResponse.model_validate(n) for n in notifications]


@router.put("/read", response_model=MessageResponse)
async def mark_notifications_read(
    data: MarkNotificationsReadRequest,
    current_user: User = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Mark notifications as read.

    - **notification_ids**: Specific IDs to mark read
    - **mark_all**: If true, marks ALL notifications as read
    """
    if data.mark_all:
        await db.execute(
            update(Notification)
            .where(
                Notification.user_id == current_user.id,
                Notification.is_read == False,  # noqa: E712
            )
            .values(is_read=True)
        )
    elif data.notification_ids:
        await db.execute(
            update(Notification)
            .where(
                Notification.user_id == current_user.id,
                Notification.id.in_(data.notification_ids),
            )
            .values(is_read=True)
        )

    await db.flush()
    return MessageResponse(message="Notifications marked as read")
