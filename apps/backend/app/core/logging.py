"""構成済みロガーの雛形。必要なフォーマットやハンドラを追加してください。"""

import logging
from typing import Literal

_LOG_LEVELS: dict[str, int] = {
    "debug": logging.DEBUG,
    "info": logging.INFO,
    "warning": logging.WARNING,
    "error": logging.ERROR,
    "critical": logging.CRITICAL,
}


def configure_logging(level: Literal["debug", "info", "warning", "error", "critical"] = "info") -> None:
    """シンプルなロギング初期化処理。"""

    logging.basicConfig(
        level=_LOG_LEVELS[level],
        format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    )
