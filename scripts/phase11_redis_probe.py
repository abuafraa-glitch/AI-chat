import asyncio
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

os.environ["REDIS_URL"] = "redis://127.0.0.1:16379/0"
os.environ["REDIS_CACHE_URL"] = "redis://127.0.0.1:16379/1"
os.environ["REDIS_QUEUE_URL"] = "redis://127.0.0.1:16379/2"

from services.redis.redis_service import RedisService


async def main() -> None:
    service = RedisService()
    await service.connect()
    if not service._connected:
        raise RuntimeError("REDIS_CONNECT_FAILED")
    await service.set_session("phase11", {"tenant_id": "tenant-a"}, ttl=60)
    session = await service.get_session("phase11")
    await service.blacklist_token("phase11-jti", ttl=60)
    blacklisted = await service.is_token_blacklisted("phase11-jti")
    task_id = await service.enqueue_task("phase11", {"tenant_id": "tenant-a", "request_id": "req-11"})
    task = await service.dequeue_task("phase11")
    lock_first = await service.acquire_lock("phase11", ttl=60)
    lock_second = await service.acquire_lock("phase11", ttl=60)
    await service.release_lock("phase11")
    stats = await service.get_stats()
    print({"connected": service._connected, "session": session, "blacklisted": blacklisted, "task_id": bool(task_id), "task": task, "lock_first": lock_first, "lock_second": lock_second, "stats_connected": stats.get("connected"), "redis_version": stats.get("version")})
    if session != {"tenant_id": "tenant-a"} or not blacklisted or not task_id or task is None or not lock_first or lock_second or not stats.get("connected"):
        raise AssertionError("REDIS_RUNTIME_PROBE_FAILED")
    await service.disconnect()


if __name__ == "__main__":
    asyncio.run(main())
