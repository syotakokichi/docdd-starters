"""FastAPI アプリの生成処理。"""

from fastapi import FastAPI

from app.core.config import get_settings
from app.core.logging import configure_logging
from app.kernel.module_loader import ModuleLoader
from app.kernel.router import attach_module_routers


def create_app() -> FastAPI:
    """FastAPI アプリを初期化し、モジュールのルータをマウントする。"""

    settings = get_settings()
    configure_logging()

    application = FastAPI(title=settings.app_name)

    loader = ModuleLoader()
    manifests = loader.discover_modules()
    attach_module_routers(application, manifests)

    return application
