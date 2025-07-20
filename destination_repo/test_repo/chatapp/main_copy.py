from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session
from typing import List
import json

from db import SessionLocal, engine
import models
import schemas
import os
import uvicorn

# データベースのテーブルを作成
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# 静的ファイルを提供するディレクトリのパス
static_dir = os.path.join(os.path.dirname(__file__), "static")

# ディレクトリが存在するか確認
if not os.path.isdir(static_dir):
    raise RuntimeError(f"Directory '{static_dir}' does not exist")


# データベース接続の依存関係
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()  # データベースセッションを終了


# WebSocket接続管理クラス
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []  # アクティブな接続を管理

    async def connect(self, websocket: WebSocket):
        await websocket.accept()  # WebSocket接続を受け入れる
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        # 全てのアクティブな接続にメッセージをブロードキャスト
        for connection in self.active_connections:
            await connection.send_text(message)


manager = ConnectionManager()

# 静的ファイルのマウント
app.mount("/static", StaticFiles(directory=static_dir), name="static")


# ルートエンドポイント、HTMLを返す
@app.get("/")
async def get():
    with open(static_dir + "/index.html", "r") as f:
        content = f.read()
    return HTMLResponse(content)


# WebSocketエンドポイント
@app.websocket("/ws/{username}")
async def websocket_endpoint(
    websocket: WebSocket, username: str, db: Session = Depends(get_db)
):
    print("おおお", websocket)
    await manager.connect(websocket)  # クライアント接続
    try:
        while True:
            data = (
                await websocket.receive_text()
            )  # クライアントからのメッセージを受信
            message = schemas.MessageCreate(
                content=data, username=username
            )  # スキーマに基づいてメッセージを作成
            db_message = models.Message(
                content=message.content, username=message.username
            )  # データベースに保存するためのメッセージを作成
            db.add(db_message)  # データベースに追加
            db.commit()  # コミットして保存
            await manager.broadcast(
                json.dumps({"username": username, "message": data})
            )  # メッセージをブロードキャスト
    except WebSocketDisconnect:
        # WebSocketが切断された場合の処理
        manager.disconnect(websocket)
        await manager.broadcast(
            json.dumps(
                {
                    "username": "system",
                    "message": f"{username} has left the chat",
                }
            )
        )
    except Exception as e:
        # その他の例外処理
        print(f"Error in WebSocket connection: {str(e)}")
        manager.disconnect(websocket)


# メッセージ取得エンドポイント
@app.get("/messages", response_model=List[schemas.Message])
def read_messages(
    skip: int = 0, limit: int = 100, db: Session = Depends(get_db)
):
    # 最新のメッセージを取得して返す
    messages = (
        db.query(models.Message)
        .order_by(models.Message.id.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return messages[::-1]  # 新しい順に並び替え


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
