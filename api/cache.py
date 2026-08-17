import json
import os
import redis

client = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    decode_responses=True,
)


def get_latest_from_cache(device_id):
    key = f"latest:{device_id}"
    cached = client.get(key)

    if cached is None:
        return None

    return json.loads(cached)


def set_latest_in_cache(device_id, measurement):
    key = f"latest:{device_id}"
    client.set(key, json.dumps(measurement))
