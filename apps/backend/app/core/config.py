"""アプリケーション全体設定のプレースホルダ。

環境変数の読み込みや設定バリデーションを行うための Pydantic Settings を定義してください。
"""

from pydantic import Field
from pydantic_settings import BaseSettings


class AppSettings(BaseSettings):
    """基本設定の例。必要に応じてフィールドを追加してください。"""

    app_name: str = Field(default="DocDD Starter API", alias="APP_NAME")
    environment: str = Field(default="local", alias="ENVIRONMENT")
    database_url: str = Field(default="sqlite+aiosqlite:///./app.db", alias="DATABASE_URL")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        populate_by_name = True


def get_settings() -> AppSettings:
    """DI で利用する設定ファクトリ。"""
    return AppSettings()
