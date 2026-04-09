from typing import Generic, TypeVar
from pydantic import BaseModel, Field


T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T] = Field(default_factory=list)
    total: int = Field(default=0, ge=0)
    skip: int = Field(default=0, ge=0)
    limit: int = Field(default=0, ge=0)
