"""Example モジュールのサービスレイヤ。"""

from dataclasses import dataclass


@dataclass
class ExampleService:
    """依存があれば __post_init__ 等で受け取れるようにしておく。"""

    message: str = "pong"

    def get_ping_message(self) -> str:
        return self.message


def get_example_service() -> ExampleService:
    """FastAPI の Depends で扱いやすいようプロバイダ関数を定義。"""

    return ExampleService()
