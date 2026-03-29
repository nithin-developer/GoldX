import uuid
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import inspect, text
from sqlalchemy.orm import DeclarativeBase
from app.core.config import settings


engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,
)

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


def _ensure_signal_public_ids(sync_conn) -> None:
    """Backfill UUID-style public ids for signals in existing databases."""
    inspector = inspect(sync_conn)
    table_names = set(inspector.get_table_names())
    if "signals" not in table_names:
        return

    signal_columns = {col["name"] for col in inspector.get_columns("signals")}
    if "public_id" not in signal_columns:
        sync_conn.execute(text("ALTER TABLE signals ADD COLUMN public_id VARCHAR(36)"))

    rows = sync_conn.execute(
        text("SELECT id FROM signals WHERE public_id IS NULL OR public_id = ''")
    ).fetchall()

    for row in rows:
        sync_conn.execute(
            text("UPDATE signals SET public_id = :public_id WHERE id = :id"),
            {"public_id": str(uuid.uuid4()), "id": row[0]},
        )

    sync_conn.execute(
        text("CREATE UNIQUE INDEX IF NOT EXISTS ix_signals_public_id ON signals (public_id)")
    )


async def get_db() -> AsyncSession:
    """Dependency that provides an async database session."""
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """Create all database tables."""
    async with engine.begin() as conn:
        from app.models import user, signal, wallet, referral, notification  # noqa: F401
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(_ensure_signal_public_ids)


async def close_db():
    """Dispose the database engine."""
    await engine.dispose()
