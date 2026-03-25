from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.notification import SupportMessage
from app.schemas.notification_schema import (
    SupportMessageResponse,
    SendSupportMessageRequest,
)


router = APIRouter(prefix="/support", tags=["Support"])


@router.get("/messages", response_model=list[SupportMessageResponse])
async def get_support_messages(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get support chat messages for the current user."""
    result = await db.execute(
        select(SupportMessage)
        .where(SupportMessage.user_id == current_user.id)
        .order_by(SupportMessage.created_at.asc())
        .offset(skip)
        .limit(limit)
    )
    messages = result.scalars().all()
    return [SupportMessageResponse.model_validate(m) for m in messages]


@router.post("/message", response_model=SupportMessageResponse, status_code=201)
async def send_support_message(
    data: SendSupportMessageRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Send a message to support."""
    message = SupportMessage(
        user_id=current_user.id,
        sender_type="user",
        message=data.message,
    )
    db.add(message)
    await db.flush()
    return SupportMessageResponse.model_validate(message)
