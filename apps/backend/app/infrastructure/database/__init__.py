"""非同期 SQLAlchemy セッション管理。"""

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import get_settings

_engine = create_async_engine(get_settings().database_url, echo=False)
_SessionLocal = async_sessionmaker(_engine, expire_on_commit=False)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI Depends で利用する非同期セッションファクトリ。"""

    async with _SessionLocal() as session:
        yield session
