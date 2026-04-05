from typing import Annotated
from fastapi import APIRouter, Depends, Path, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.security import hash_password
from app.models.user import User
from app.schemas.user_schema import UserListResponse, AdminUserUpdate
from app.schemas.auth_schema import MessageResponse


router = APIRouter(prefix="/admin/users", tags=["Admin - Users"])


@router.get("", response_model=list[UserListResponse])
async def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    role: str = Query(None, pattern="^(user|admin)$"),
    search: str = Query(None),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    List all users (admin only).
    Supports filtering by role and searching by email/name.
    """
    query = select(User)

    if role:
        query = query.where(User.role == role)

    if search:
        search_filter = f"%{search}%"
        query = query.where(
            User.email.ilike(search_filter) | User.full_name.ilike(search_filter)
        )

    query = query.order_by(User.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    users = result.scalars().all()
    return [UserListResponse.model_validate(u) for u in users]


@router.get("/{user_id}", response_model=UserListResponse)
async def get_user(
    user_id: Annotated[int, Path(ge=1000000, le=9999999)],
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get a specific user's details (admin only)."""
    from fastapi import HTTPException

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserListResponse.model_validate(user)


@router.put("/{user_id}", response_model=UserListResponse)
async def update_user(
    user_id: Annotated[int, Path(ge=1000000, le=9999999)],
    data: AdminUserUpdate,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Update a user's details (admin only).
    Can modify: name, phone, active status, VIP level, role, wallet balance.
    """
    from fastapi import HTTPException

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if value is not None:
            setattr(user, key, value)

    await db.flush()
    return UserListResponse.model_validate(user)


@router.post("/{user_id}/reset-withdrawal-password", response_model=MessageResponse)
async def reset_withdrawal_password(
    user_id: Annotated[int, Path(ge=1000000, le=9999999)],
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Reset a user's withdrawal password to GoldX@1234 (admin only).
    """
    from fastapi import HTTPException

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Hash the default password and set it as the withdrawal password
    default_password = "GoldX@1234"
    user.withdrawal_password_hash = hash_password(default_password)

    await db.flush()
    return MessageResponse(message=f"Withdrawal password reset to {default_password}")


@router.delete("/{user_id}", response_model=MessageResponse)
async def delete_user(
    user_id: Annotated[int, Path(ge=1000000, le=9999999)],
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete a user (admin only).
    """
    from fastapi import HTTPException
    from sqlalchemy import delete

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Delete the user
    await db.execute(delete(User).where(User.id == user_id))
    await db.flush()

    return MessageResponse(message="User deleted successfully")
