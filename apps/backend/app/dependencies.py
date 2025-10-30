"""FastAPI で共有する依存解決関数をまとめるモジュール。"""

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession

from app.shared import get_session


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """SQLAlchemy のセッションを提供する依存関数。"""

    async for session in get_session():
        yield session
