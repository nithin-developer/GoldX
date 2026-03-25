import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.core.database import init_db, close_db
from app.routes.auth_routes import router as auth_router
from app.routes.user_routes import router as user_router, dashboard_router
from app.routes.wallet_routes import router as wallet_router
from app.routes.signal_routes import router as signal_router
from app.routes.referral_routes import router as referral_router
from app.routes.notification_routes import router as notification_router
from app.routes.support_routes import router as support_router
from app.routes.admin.users_admin import router as admin_users_router
from app.routes.admin.signals_admin import router as admin_signals_router
from app.routes.admin.reports_admin import router as admin_reports_router

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


# Rate limiter
limiter = Limiter(key_func=get_remote_address)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle manager."""
    logger.info("Starting up Trading Signals API...")

    # Initialize database
    await init_db()
    logger.info("Database initialized")

    # Seed admin user
    await seed_admin_user()

    # Start background workers
    profit_task = asyncio.create_task(start_background_workers())

    yield

    # Shutdown
    profit_task.cancel()
    await close_db()
    logger.info("Trading Signals API shut down")


async def seed_admin_user():
    """Create default admin user if it doesn't exist."""
    from app.core.database import async_session_factory
    from app.models.user import User
    from app.core.security import hash_password
    from sqlalchemy import select

    async with async_session_factory() as session:
        result = await session.execute(
            select(User).where(User.email == settings.ADMIN_EMAIL)
        )
        admin = result.scalar_one_or_none()

        if not admin:
            admin = User(
                email=settings.ADMIN_EMAIL,
                password_hash=hash_password(settings.ADMIN_PASSWORD),
                full_name="System Admin",
                role="admin",
                invite_code="ADMIN001",
            )
            session.add(admin)
            await session.commit()
            logger.info(f"Admin user created: {settings.ADMIN_EMAIL}")
        else:
            logger.info("Admin user already exists")


async def start_background_workers():
    """Start background profit and VIP workers."""
    from app.workers.profit_worker import run_periodic_profit_worker
    from app.workers.vip_worker import run_periodic_vip_worker

    try:
        await asyncio.gather(
            run_periodic_profit_worker(interval_seconds=60),
            run_periodic_vip_worker(interval_seconds=86400),
        )
    except asyncio.CancelledError:
        logger.info("Background workers stopped")


# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    description=(
        "Trading Signals Platform API — manage users, wallets, signals, "
        "referrals, notifications, and support. JWT-based auth with RBAC."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_origin_regex=settings.CORS_ALLOW_ORIGIN_REGEX,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"},
    )


# Health check
@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": settings.APP_NAME}


# Register all routers under /api/v1
api_prefix = settings.API_V1_PREFIX

app.include_router(auth_router, prefix=api_prefix)
app.include_router(user_router, prefix=api_prefix)
app.include_router(dashboard_router, prefix=api_prefix)
app.include_router(wallet_router, prefix=api_prefix)
app.include_router(signal_router, prefix=api_prefix)
app.include_router(referral_router, prefix=api_prefix)
app.include_router(notification_router, prefix=api_prefix)
app.include_router(support_router, prefix=api_prefix)
app.include_router(admin_users_router, prefix=api_prefix)
app.include_router(admin_signals_router, prefix=api_prefix)
app.include_router(admin_reports_router, prefix=api_prefix)
