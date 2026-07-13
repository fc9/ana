import asyncio
from pathlib import Path

import asyncpg

from app.core.config import settings

MIGRATIONS_DIR = Path(__file__).resolve().parent / "migrations"


async def _get_last_migration(conn: asyncpg.Connection) -> str:
    try:
        row = await conn.fetchrow("SELECT value FROM meta WHERE key = 'last_migration'")
    except asyncpg.UndefinedTableError:
        return ""
    return row["value"] if row else ""


async def _set_last_migration(conn: asyncpg.Connection, filename: str) -> None:
    await conn.execute(
        """
        INSERT INTO meta (key, value, updated_at)
        VALUES ('last_migration', $1, now())
        ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()
        """,
        filename,
    )


async def run_migrations() -> None:
    conn = await asyncpg.connect(
        host=settings.postgres_host,
        port=settings.postgres_port,
        user=settings.postgres_user,
        password=settings.postgres_password,
        database=settings.postgres_db,
    )
    try:
        last_migration = await _get_last_migration(conn)
        pending = sorted(
            path for path in MIGRATIONS_DIR.glob("*.sql") if path.name > last_migration
        )
        if not pending:
            print("nenhuma migration pendente")
            return
        for path in pending:
            sql = path.read_text(encoding="utf-8")
            async with conn.transaction():
                await conn.execute(sql)
                await _set_last_migration(conn, path.name)
            print(f"aplicada: {path.name}")
    finally:
        await conn.close()


def main() -> None:
    asyncio.run(run_migrations())


if __name__ == "__main__":
    main()
