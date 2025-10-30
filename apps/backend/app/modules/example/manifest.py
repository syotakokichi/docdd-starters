"""Example モジュールのマニフェスト。"""

from app.kernel.module_loader import ModuleManifest

from .api.routes import router


def get_manifest() -> ModuleManifest:
    """Example モジュールのメタデータとルータを登録する。"""

    return ModuleManifest(
        name="example",
        description="サンプルモジュール。モジュラーモノリスでの実装方針の参考用",
        api_prefix="/example",
        routers=[router],
    )
