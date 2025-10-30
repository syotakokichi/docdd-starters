"""FastAPI アプリにモジュールのルータをマウントするヘルパー。"""

from fastapi import FastAPI

from app.kernel.module_loader import ModuleManifest


def attach_module_routers(app: FastAPI, manifests: list[ModuleManifest]) -> None:
    """モジュールマニフェストを元に FastAPI へルータを登録する。"""

    for manifest in manifests:
        for router in manifest.routers:
            prefix = manifest.api_prefix or f"/{manifest.name}"
            app.include_router(router, prefix=prefix, tags=[manifest.name])
