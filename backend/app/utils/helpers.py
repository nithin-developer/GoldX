import uuid
import string
import random
from datetime import datetime, timezone


def generate_unique_code(prefix: str = "", length: int = 8) -> str:
    """Generate a unique code with optional prefix."""
    chars = string.ascii_uppercase + string.digits
    code = "".join(random.choices(chars, k=length))
    return f"{prefix}{code}" if prefix else code


def generate_invite_code() -> str:
    """Generate a unique invite code for a user."""
    return f"INV{uuid.uuid4().hex[:8].upper()}"


def utc_now() -> datetime:
    """Get current UTC time with timezone info."""
    return datetime.now(timezone.utc)


def format_amount(amount) -> str:
    """Format a numeric amount to 2 decimal places."""
    return f"{float(amount):.2f}"


def paginate_params(skip: int = 0, limit: int = 50) -> dict:
    """Return standardized pagination parameters."""
    return {"skip": max(0, skip), "limit": min(max(1, limit), 100)}
