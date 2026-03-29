from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    full_name: Optional[str] = Field(None, max_length=255)
    phone: Optional[str] = Field(None, max_length=50)
    invite_code: str = Field(..., min_length=1, max_length=50)


class LoginRequest(BaseModel):
    email: str = Field(..., min_length=1, max_length=255)
    password: str = Field(..., min_length=1)


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=8, max_length=128)


class SetWithdrawalPasswordRequest(BaseModel):
    new_withdrawal_password: Optional[str] = Field(None, min_length=6, max_length=64)
    withdrawal_password: Optional[str] = Field(None, min_length=6, max_length=64)
    current_withdrawal_password: Optional[str] = Field(
        None, min_length=1, max_length=64
    )


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class MessageResponse(BaseModel):
    message: str
