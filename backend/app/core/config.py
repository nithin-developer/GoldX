from pydantic_settings import BaseSettings
from typing import List
import json


class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:password@localhost:5432/trading_signals"

    # JWT
    SECRET_KEY: str = "dev-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # App
    APP_NAME: str = "Trading Signals API"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api/v1"
    UPLOADS_DIR: str = "./uploads"

    # CORS
    CORS_ORIGINS: str = (
        '["http://localhost:3000","http://localhost:5173","http://127.0.0.1:5173","http://localhost:8080"]'
    )
    CORS_ALLOW_ORIGIN_REGEX: str = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"

    # Admin seed
    ADMIN_EMAIL: str = "admin@tradingsignals.com"
    ADMIN_PASSWORD: str = "admin123456"

    @property
    def cors_origins_list(self) -> List[str]:
        raw = self.CORS_ORIGINS.strip()

        # Support JSON array and comma-separated formats for env convenience.
        if raw.startswith("["):
            origins = json.loads(raw)
        else:
            origins = [item.strip() for item in raw.split(",") if item.strip()]

        return [origin.rstrip("/") for origin in origins]

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
