"""Example モジュールの API ルータ。"""

from fastapi import APIRouter, Depends

from app.modules.example.services import ExampleService, get_example_service

router = APIRouter()


@router.get("/ping", summary="ヘルスチェック用の簡易エンドポイント")
async def ping(service: ExampleService = Depends(get_example_service)) -> dict[str, str]:
    """サービスレイヤを経由したサンプルレスポンスを返す。"""

    return {"message": service.get_ping_message()}
