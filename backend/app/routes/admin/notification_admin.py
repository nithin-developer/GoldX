from typing import List
from fastapi import APIRouter, Depends, Path, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete, func
from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.models.user import User
from app.models.notification import Notification
from app.schemas.auth_schema import MessageResponse
from app.schemas.common_schema import PaginatedResponse
from app.schemas.notification_schema import NotificationResponse


router = APIRouter(prefix="/admin/notifications", tags=["Admin - Notifications"])


@router.get("", response_model=PaginatedResponse[NotificationResponse])
async def list_notifications(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    List all notifications (admin only).
    """
    total_result = await db.execute(select(func.count(Notification.id)))
    total = int(total_result.scalar_one() or 0)

    query = select(Notification).order_by(Notification.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    notifications = result.scalars().all()
    return PaginatedResponse[NotificationResponse](
        items=[NotificationResponse.model_validate(n) for n in notifications],
        total=total,
        skip=skip,
        limit=limit,
    )


@router.delete("/{notification_id}", response_model=MessageResponse)
async def delete_notification(
    notification_id: int,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete a notification (admin only).
    """
    from fastapi import HTTPException

    # Check if notification exists
    result = await db.execute(
        select(Notification).where(Notification.id == notification_id)
    )
    notification = result.scalar_one_or_none()

    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")

    # Delete the notification
    await db.execute(delete(Notification).where(Notification.id == notification_id))
    await db.flush()

    return MessageResponse(message="Notification deleted successfully")