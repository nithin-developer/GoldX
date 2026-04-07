from fastapi import APIRouter, Body, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.models.user import User
from app.schemas.signal_schema import (
    SignalResponse,
    CreateSignalRequest,
    UpdateSignalRequest,
    SignalCodeResponse,
    GenerateCodeRequest,
)
from app.schemas.auth_schema import MessageResponse
from app.services import signal_service


router = APIRouter(prefix="/admin/signals", tags=["Admin - Signals"])


@router.get("", response_model=list[SignalResponse])
async def list_signals(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """List all signals (admin only)."""
    signals = await signal_service.get_all_signals(db, skip, limit)
    return [SignalResponse.model_validate(s) for s in signals]


@router.post("", response_model=SignalResponse, status_code=201)
async def create_signal(
    data: CreateSignalRequest,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new trading signal (admin only).

    - **asset**: Trading asset (e.g., BTC, ETH)
    - **direction**: 'long' or 'short'
    - **profit_percent**: Expected profit percentage
    - **duration_hours**: Signal duration value
    - **duration_unit**: 'hours' or 'minutes'
    """
    signal = await signal_service.create_signal(
        data.asset,
        data.direction,
        data.profit_percent,
        data.duration_hours,
        data.duration_unit,
        data.vip_only,
        db,
    )
    return SignalResponse.model_validate(signal)


@router.put("/{signal_id}", response_model=SignalResponse)
async def update_signal(
    signal_id: str,
    data: UpdateSignalRequest,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Update an existing signal (admin only)."""
    update_data = data.model_dump(exclude_unset=True)
    signal = await signal_service.update_signal(signal_id, update_data, db)
    return SignalResponse.model_validate(signal)


@router.delete("/{signal_id}", response_model=MessageResponse)
async def delete_signal(
    signal_id: str,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Delete a signal (admin only)."""
    await signal_service.delete_signal(signal_id, db)
    return MessageResponse(message="Signal deleted successfully")


@router.post("/{signal_id}/generate-code", response_model=SignalCodeResponse, status_code=201)
async def generate_signal_codes(
    signal_id: str,
    data: GenerateCodeRequest = Body(default_factory=GenerateCodeRequest),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Generate or retrieve the single activation code for a signal (admin only).

    If no request body is sent, defaults are used:
    - **expires_in_hours**: 24h (max 720h)
    - **count**: must be 1 (only one code per signal)
    """
    code = await signal_service.generate_signal_codes(
        signal_id, data.expires_in_hours, data.count, db
    )
    return SignalCodeResponse.model_validate(code)
