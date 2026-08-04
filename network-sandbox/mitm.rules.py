import os
import re
from mitmproxy import http, ctx


def env_set(name: str) -> set[str]:
    env_value = os.getenv(name, "").strip()
    env_value_split = re.split(r"[\s,]+", env_value)
    return {
        value.strip().lower()
        for value in env_value_split
        if value.strip()
    }

DENY = env_set("HTTP_DENY_ALL")
ALLOW = env_set("HTTP_ALLOW_ALL")
SAFE_METHODS = env_set("HTTP_SAFE_METHODS") or {"get"}

ctx.log.info(f"Allow all: {ALLOW}")
ctx.log.info(f"Deny all: {DENY}")
ctx.log.info(f"Default allowed method: {SAFE_METHODS}")


def request(flow: http.HTTPFlow):
    host = flow.request.pretty_host.lower()
    method = flow.request.method.lower()

    if host in ALLOW:
        return

    if host in DENY or method not in SAFE_METHODS:
        flow.response = http.Response.make(
            403,
            b"Blocked by proxy policy\n",
            {"Content-Type": "text/plain"},
        )
