"""
WebSocket endpoint for real-time download progress updates.

Subscribes to Redis pub/sub for progress events and forwards to connected clients.
"""
import asyncio
import json
from typing import List

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.redis import get_redis

router = APIRouter(tags=["websocket"])


class ConnectionManager:
    """Manages WebSocket connections for broadcasting progress updates."""

    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        """Send message to all connected clients."""
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception:
                disconnected.append(connection)

        # Clean up disconnected clients
        for conn in disconnected:
            self.disconnect(conn)


manager = ConnectionManager()


@router.websocket("/ws/progress")
async def websocket_progress(websocket: WebSocket):
    """
    WebSocket endpoint for real-time download progress.

    Subscribes to Redis pub/sub for progress updates and forwards to client.
    Supports ping/pong keepalive.

    Message format:
    {
        "type": "progress",
        "video_id": "abc123",
        "percent": 42,
        "downloaded_bytes": 1048576,
        "total_bytes": 2097152
    }
    """
    await manager.connect(websocket)
    redis = await get_redis()
    pubsub = redis.pubsub()

    try:
        # Subscribe to all progress channels using pattern matching
        await pubsub.psubscribe("progress:*")

        while True:
            # Check for Redis messages (non-blocking with timeout)
            try:
                message = await asyncio.wait_for(
                    pubsub.get_message(ignore_subscribe_messages=True),
                    timeout=0.1
                )

                if message and message["type"] == "pmessage":
                    # Extract video_id from channel name (progress:video_id)
                    channel = message["channel"]
                    if isinstance(channel, bytes):
                        channel = channel.decode()
                    video_id = channel.split(":")[1]

                    # Parse progress data
                    data_str = message["data"]
                    if isinstance(data_str, bytes):
                        data_str = data_str.decode()
                    data = json.loads(data_str)

                    # Send to WebSocket client
                    await websocket.send_json({
                        "type": "progress",
                        "video_id": video_id,
                        "percent": data.get("percent", 0),
                        "downloaded_bytes": data.get("downloaded_bytes"),
                        "total_bytes": data.get("total_bytes")
                    })

            except asyncio.TimeoutError:
                pass

            # Check for WebSocket messages (ping/pong keepalive)
            try:
                data = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=0.1
                )
                if data == "ping":
                    await websocket.send_text("pong")
            except asyncio.TimeoutError:
                pass

    except WebSocketDisconnect:
        pass
    except Exception:
        pass
    finally:
        manager.disconnect(websocket)
        try:
            await pubsub.punsubscribe("progress:*")
            await pubsub.close()
        except Exception:
            pass
