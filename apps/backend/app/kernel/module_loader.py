"""モジュールの自動読み込みを行うシンプルなローダー。"""

from __future__ import annotations

import importlib
import pkgutil
from dataclasses import dataclass, field
from typing import Iterable

from fastapi import APIRouter


@dataclass
class ModuleManifest:
    """各モジュールが公開する情報を保持するデータクラス。"""

    name: str
    version: str = "0.1.0"
    description: str | None = None
    api_prefix: str | None = None
    routers: list[APIRouter] = field(default_factory=list)
    dependencies: list[str] = field(default_factory=list)


class ModuleLoader:
    """``app.modules`` を探索し、モジュールの manifest を収集するローダー。"""

    allowed_modules: set[str]

    def __init__(self, modules_path: str = "app.modules", *, allowed_modules: Iterable[str] | None = None) -> None:
        self.modules_path = modules_path
        self.allowed_modules = set(allowed_modules or {"example"})

    def discover_modules(self) -> list[ModuleManifest]:
        """マニフェストを読み込み、 FastAPI への組み込みに利用する。"""

        manifests: list[ModuleManifest] = []

        modules_pkg = importlib.import_module(self.modules_path)
        if not hasattr(modules_pkg, "__path__"):
            return []

        for module_info in pkgutil.iter_modules(modules_pkg.__path__):
            if module_info.name.startswith("_"):
                continue
            if self.allowed_modules and module_info.name not in self.allowed_modules:
                continue

            manifest = self._load_manifest(module_info.name)
            if manifest:
                manifests.append(manifest)

        return manifests

    def _load_manifest(self, module_name: str) -> ModuleManifest | None:
        module = importlib.import_module(f"{self.modules_path}.{module_name}.manifest")
        get_manifest = getattr(module, "get_manifest", None)
        if not callable(get_manifest):
            return None
        manifest = get_manifest()
        if not isinstance(manifest, ModuleManifest):
            raise TypeError(f"Manifest for {module_name} must return ModuleManifest")
        return manifest
