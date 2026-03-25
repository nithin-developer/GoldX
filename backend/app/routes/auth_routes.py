from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.auth_schema import (
    RegisterRequest,
    LoginRequest,
    ChangePasswordRequest,
    RefreshTokenRequest,
    TokenResponse,
    MessageResponse,
)
from app.schemas.user_schema import UserProfileResponse
from app.services import auth_service


router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """
    Register a new user account.

    - **email**: Valid email address (unique)
    - **password**: Minimum 8 characters
    - **full_name**: Optional display name
    - **phone**: Optional phone number
    - **invite_code**: Required referral invite code
    """
    user = await auth_service.register_user(data, db)

    # Auto-login after registration
    from app.core.security import create_access_token, create_refresh_token

    token_data = {"user_id": user.id, "role": user.role}
    return TokenResponse(
        access_token=create_access_token(token_data),
        refresh_token=create_refresh_token(token_data),
    )


@router.get("/validate-invite/{invite_code}", response_model=MessageResponse)
async def validate_invite(invite_code: str, db: AsyncSession = Depends(get_db)):
    """Validate whether an invite code can be used for registration."""
    await auth_service.validate_invite_code(invite_code, db)
    return MessageResponse(message="Invite code is valid")


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Authenticate user and receive JWT tokens.

    Returns access_token (30 min) and refresh_token (7 days).
    """
    return await auth_service.login_user(data, db)


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(data: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    """
    Refresh the access token using a valid refresh token.
    """
    return await auth_service.refresh_access_token(data.refresh_token, db)


@router.get("/me", response_model=UserProfileResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """
    Get the current authenticated user's profile.
    """
    return UserProfileResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        role=current_user.role,
        is_active=current_user.is_active,
        invite_code=current_user.invite_code,
        wallet_balance=current_user.wallet_balance,
        vip_level=current_user.vip_level,
        has_withdrawal_password=current_user.withdrawal_password_hash is not None,
        created_at=current_user.created_at,
    )


@router.post("/change-password", response_model=MessageResponse)
async def change_password(
    data: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Change the current user's password.
    """
    await auth_service.change_password(
        current_user, data.current_password, data.new_password, db
    )
    return MessageResponse(message="Password changed successfully")
