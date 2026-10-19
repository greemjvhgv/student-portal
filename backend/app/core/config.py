"""
Owner: Ruan (backend: project structure + authentication).

Settings loaded from environment variables / a local .env file.
Set SECRET_KEY in backend/.env for anything beyond local dev.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Dev-only fallback so the prototype runs out of the box. Override it.
    SECRET_KEY: str = "dev-only-secret-key-change-me-in-env-file"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 12 * 60


settings = Settings()
