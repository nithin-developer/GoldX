import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException, status
from app.models.user import User
from app.models.referral import Referral
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.schemas.auth_schema import RegisterRequest, LoginRequest, TokenResponse


async def register_user(data: RegisterRequest, db: AsyncSession) -> User:
    """Register a new user account."""
    normalized_email = data.email.strip().lower()
    normalized_invite_code = data.invite_code.strip().upper()

    if not normalized_invite_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invite code is required",
        )

    # Check if email already exists
    result = await db.execute(
        select(User).where(func.lower(User.email) == normalized_email)
    )
    existing_user = result.scalar_one_or_none()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    # Validate invite code before creating account.
    referrer_result = await db.execute(
        select(User).where(func.upper(User.invite_code) == normalized_invite_code)
    )
    referrer = referrer_result.scalar_one_or_none()
    if not referrer:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid invite code",
        )

    # Generate unique invite code for the new user
    invite_code = f"INV{uuid.uuid4().hex[:8].upper()}"

    # Create user
    user = User(
        email=normalized_email,
        password_hash=hash_password(data.password),
        full_name=data.full_name,
        phone=data.phone,
        invite_code=invite_code,
        referred_by=referrer.id,
        role="user",
    )

    db.add(user)
    await db.flush()

    referral = Referral(
        referrer_id=referrer.id,
        referred_user_id=user.id,
        status="pending",
    )
    db.add(referral)

    await db.flush()
    return user


async def validate_invite_code(invite_code: str, db: AsyncSession) -> None:
    """Ensure invite code exists and is active for referral onboarding."""
    normalized_invite_code = invite_code.strip().upper()
    if not normalized_invite_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invite code is required",
        )
    
    result = await db.execute(
        select(User).where(func.upper(User.invite_code) == normalized_invite_code)
    )
    referrer = result.scalar_one_or_none()
    if not referrer:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid invite code",
        )


async def login_user(data: LoginRequest, db: AsyncSession) -> TokenResponse:
    """Authenticate user and return tokens."""
    normalized_email = data.email.strip().lower()

    result = await db.execute(
        select(User).where(func.lower(User.email) == normalized_email)
    )
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated. Contact support.",
        )

    # Create tokens
    token_data = {"user_id": user.id, "role": user.role}
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
    )


async def refresh_access_token(refresh_token: str, db: AsyncSession) -> TokenResponse:
    """Generate new access token from refresh token."""
    payload = decode_token(refresh_token)

    if payload is None or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    user_id = payload.get("user_id")
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or deactivated",
        )

    token_data = {"user_id": user.id, "role": user.role}
    new_access_token = create_access_token(token_data)
    new_refresh_token = create_refresh_token(token_data)

    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
    )


async def change_password(
    user: User, current_password: str, new_password: str, db: AsyncSession
) -> None:
    """Change user's password."""
    if not verify_password(current_password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect",
        )

    user.password_hash = hash_password(new_password)
    await db.flush()
