from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.signal_schema import (
    SignalResponse,
    ActivateSignalRequest,
    UserSignalEntryResponse,
)
from app.schemas.auth_schema import MessageResponse
from app.services import signal_service


router = APIRouter(prefix="/signals", tags=["Signals"])


@router.get("", response_model=list[SignalResponse])
async def get_signals(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all currently active signals."""
    signals = await signal_service.get_active_signals(db, user_id=current_user.id)
    return [SignalResponse.model_validate(s) for s in signals]


@router.get("/all", response_model=list[SignalResponse])
async def get_all_signals(
    status: str | None = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all signals from DB for authenticated users (optionally filtered by status)."""
    signals = await signal_service.get_all_signals(
        db,
        skip,
        limit,
        user_id=current_user.id,
    )

    if status is not None:
        normalized = status.strip().lower()
        signals = [s for s in signals if (s.status or "").lower() == normalized]

    return [SignalResponse.model_validate(s) for s in signals]


@router.post("/activate", response_model=UserSignalEntryResponse, status_code=201)
async def activate_signal(
    data: ActivateSignalRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Activate a signal using a signal code.

    Flow:
    1. Validate code exists
    2. Check code has not expired
    3. Verify signal is active and user is eligible
    4. Ensure user has not already activated that signal
    5. Verify user has minimum $100 wallet balance
    6. Create signal entry with user's current balance
    """
    entry = await signal_service.activate_signal(current_user, data.signal_code, db)
    return UserSignalEntryResponse.model_validate(entry)


@router.get("/history", response_model=list[UserSignalEntryResponse])
async def get_signal_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get the current user's signal participation history."""
    entries = await signal_service.get_user_signal_history(current_user, db, skip, limit)
    return [UserSignalEntryResponse.model_validate(e) for e in entries]
