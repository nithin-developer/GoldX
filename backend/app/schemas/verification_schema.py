from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class VerificationStatusResponse(BaseModel):
    user_id: int
    status: str
    id_document_url: Optional[str] = None
    selfie_document_url: Optional[str] = None
    address_document_url: Optional[str] = None
    submitted_at: Optional[datetime] = None
    reviewed_at: Optional[datetime] = None
    reviewed_by_admin_id: Optional[int] = None
    rejection_reason: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class AdminVerificationListItemResponse(BaseModel):
    verification_id: int
    user_id: int
    user_email: str
    user_full_name: Optional[str] = None
    status: str
    id_document_url: Optional[str] = None
    selfie_document_url: Optional[str] = None
    address_document_url: Optional[str] = None
    submitted_at: Optional[datetime] = None
    reviewed_at: Optional[datetime] = None
    reviewed_by_admin_id: Optional[int] = None
    rejection_reason: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class AdminVerificationApproveRequest(BaseModel):
    admin_note: Optional[str] = Field(None, max_length=500)


class AdminVerificationRejectRequest(BaseModel):
    rejection_reason: str = Field(..., min_length=3, max_length=500)
