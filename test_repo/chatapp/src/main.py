from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware  # CORSミドルウェアの追加
import uvicorn
import os

app = FastAPI()

# CORSの設定を追加
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # すべてのオリジンを許可（必要に応じて限定する）
    allow_credentials=True,
    allow_methods=["*"],  # すべてのHTTPメソッドを許可
    allow_headers=["*"],  # すべてのHTTPヘッダーを許可
)
# 静的ファイルを提供するディレクトリのパス
static_dir = os.path.join(os.path.dirname(__file__), "static")

# ディレクトリが存在するか確認
if not os.path.isdir(static_dir):
    raise RuntimeError(f"Directory '{static_dir}' does not exist")

# 静的ファイルのマウント
app.mount("/static", StaticFiles(directory=static_dir), name="static")


# ルートエンドポイント、HTMLを返す
@app.get("/")
async def get():
    with open(static_dir + "/index.html", "r") as f:
        content = f.read()
    return HTMLResponse(content)


# 1. WebSocketエンドポイントの定義
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    # 2. WebSocket接続の確立
    await websocket.accept()

    try:
        # 4. 接続の維持
        while True:
            # 3. メッセージの送受信
            data = await websocket.receive_text()
            await websocket.send_text(f"Message received: {data}")

    except WebSocketDisconnect:
        # 5. エラー処理 (接続エラーを処理する)
        print("Client disconnected")

    finally:
        # 6. リソースの解放 (必要に応じてクリーンアップ)
        print("Cleaning up resources")


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
