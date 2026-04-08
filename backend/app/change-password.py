import asyncio
import sys
from pathlib import Path

from sqlalchemy import select


BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
	sys.path.insert(0, str(BACKEND_ROOT))

from app.core.config import settings
from app.core.database import async_session_factory
from app.core.security import hash_password
from app.models.user import User


NEW_ADMIN_PASSWORD = "Admin@goldx.com"


async def reset_admin_password(new_password: str = NEW_ADMIN_PASSWORD) -> None:
	async with async_session_factory() as session:
		admin_result = await session.execute(
			select(User).where(User.email == settings.ADMIN_EMAIL)
		)
		admin_user = admin_result.scalar_one_or_none()

		if admin_user is None:
			fallback_result = await session.execute(
				select(User).where(User.role == "admin").order_by(User.id.asc()).limit(1)
			)
			admin_user = fallback_result.scalar_one_or_none()

		if admin_user is None:
			raise RuntimeError("No admin user found in database.")

		admin_user.password_hash = hash_password(new_password)
		await session.commit()

		print(f"Admin password updated successfully for: {admin_user.email}")
		print(f"New password: {new_password}")


if __name__ == "__main__":
	asyncio.run(reset_admin_password())
