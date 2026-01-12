# ミドルウェア実装

> FastAPI ミドルウェアのパターン。

## 基本構造

```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # リクエスト前の処理
        start_time = time.time()

        # 次のミドルウェア/エンドポイントを呼び出し
        response = await call_next(request)

        # レスポンス後の処理
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = str(process_time)

        return response
```

## ミドルウェア登録

```python
# kernel/app.py
from fastapi import FastAPI
from starlette.middleware.cors import CORSMiddleware

def create_app() -> FastAPI:
    app = FastAPI()

    # CORS（最初に登録）
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ログ
    app.add_middleware(LoggingMiddleware)

    return app
```

## 認証ミドルウェアの代替: Depends

FastAPI では認証は Middleware より Depends パターンを推奨。

```python
# shared/auth/__init__.py
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    settings: AppSettings = Depends(get_settings),
) -> AuthContext:
    """JWT トークンからユーザー情報を取得"""
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.jwt_secret,
            algorithms=["HS256"],
            audience=settings.jwt_audience,
        )
        return AuthContext(
            user_id=UUID(payload["sub"]),
            role=payload["role"],
        )
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="認証が必要です")
```

## リクエストログミドルウェア

```python
class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = str(uuid4())[:8]
        logger.info(
            "Request: %s %s [%s]",
            request.method,
            request.url.path,
            request_id,
        )

        response = await call_next(request)

        logger.info(
            "Response: %s %s -> %d [%s]",
            request.method,
            request.url.path,
            response.status_code,
            request_id,
        )
        return response
```

## ミドルウェアの実行順序

登録順と逆順で実行される（ラッピング構造）。

```
リクエスト
  ↓ CORS（外側）
    ↓ Logging（内側）
      ↓ エンドポイント
    ↓ Logging
  ↓ CORS
レスポンス
```

## 関連ドキュメント

- [FastAPI Middleware](https://fastapi.tiangolo.com/tutorial/middleware/)
- [Starlette Middleware](https://www.starlette.io/middleware/)
