from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# `src/.env` é compartilhado por todos os apps de `src/apps/` (ver
# docs/dev/architecture/03-backend.md > Estrutura).
_ENV_FILE = Path(__file__).resolve().parents[4] / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=_ENV_FILE, extra="ignore")

    # PostgreSQL (ver docs/dev/architecture/07-database.md). 127.0.0.1 em
    # vez de localhost — resolução dual-stack de "localhost" no asyncio
    # pode ser instável/lenta em alguns ambientes (ex: Windows).
    postgres_host: str = "127.0.0.1"
    postgres_port: int = 5432
    postgres_db: str = "ana"
    postgres_user: str = "ana"
    postgres_password: str = "ana"

    # Redis (ver docs/dev/architecture/08-redis.md)
    redis_host: str = "127.0.0.1"
    redis_port: int = 6379

    # GuardService (ver docs/dev/architecture/06b-services.md)
    max_attachments_per_message: int = 10
    min_text_length: int = 2

    # ProviderCacheService (ver docs/dev/architecture/06b-services.md e
    # 08-redis.md)
    provider_cache_refresh_seconds: int = 60
    provider_cache_refresh_seconds_external: int = 3600

    # CredentialCipher (AES-256-GCM, ver docs/dev/architecture/06b-services.md)
    ana_credentials_master_key: str = ""
    ana_credentials_key_id: str = "master-2026-01"

    @property
    def database_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )

    @property
    def redis_url(self) -> str:
        return f"redis://{self.redis_host}:{self.redis_port}/0"


settings = Settings()
