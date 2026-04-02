import random
import re
import secrets
import string
from datetime import datetime, timezone


INVITE_CODE_LENGTH = 8
_INVITE_CODE_PATTERN = re.compile(r"^[A-Z0-9]{8}$")
_INVITE_CODE_CHARS = string.ascii_uppercase + string.digits


def generate_unique_code(prefix: str = "", length: int = 8) -> str:
    """Generate a unique code with optional prefix."""
    chars = string.ascii_uppercase + string.digits
    code = "".join(random.choices(chars, k=length))
    return f"{prefix}{code}" if prefix else code


def generate_invite_code() -> str:
    """Generate an 8-character referral code for a user."""
    return "".join(secrets.choice(_INVITE_CODE_CHARS) for _ in range(INVITE_CODE_LENGTH))


def normalize_invite_code(invite_code: str | None) -> str:
    """Normalize invite code input into uppercase and strip legacy prefix."""
    normalized = (invite_code or "").strip().upper()
    if (
        normalized.startswith("INV")
        and len(normalized) == 11
        and _INVITE_CODE_PATTERN.fullmatch(normalized[3:]) is not None
    ):
        normalized = normalized[3:]
    return normalized


def is_valid_invite_code(invite_code: str | None) -> bool:
    """Return True when invite code matches the expected 8-char format."""
    normalized = normalize_invite_code(invite_code)
    return _INVITE_CODE_PATTERN.fullmatch(normalized) is not None


def utc_now() -> datetime:
    """Get current UTC time with timezone info."""
    return datetime.now(timezone.utc)


def format_amount(amount) -> str:
    """Format a numeric amount to 2 decimal places."""
    return f"{float(amount):.2f}"


def paginate_params(skip: int = 0, limit: int = 50) -> dict:
    """Return standardized pagination parameters."""
    return {"skip": max(0, skip), "limit": min(max(1, limit), 100)}
