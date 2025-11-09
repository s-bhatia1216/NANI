# FastAPI service that your app or Google Sheet endpoint receives data from.

import os, requests, threading, time
from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
from beam import BeamWatcher

PIN = int(os.getenv("PIN", "27"))
DEFAULT_URL = os.getenv("URL", "")       # e.g. Google Apps Script URL
DEVICE = os.getenv("DEVICE", "pi3-nani")
HEARTBEAT_SEC = int(os.getenv("HEARTBEAT", "30"))

app = FastAPI(title="NANI Beam API")
watcher = BeamWatcher(pin=PIN)
state = {"running": False, "value": None, "last_event": None, "url": DEFAULT_URL}

def push(value: int, ts: str, event_override=None):
    """Send data to the configured URL."""
    state["value"] = value
    state["last_event"] = ts
    url = state["url"]
    if not url:
        return
    event = event_override or ("BLOCKED" if value == 0 else "CLEAR")
    try:
        requests.post(
            url,
            json={
                "event": event,
                "value": int(value),
                "pin": PIN,
                "device": DEVICE,
                "ts": ts,
            },
            timeout=4,
        )
    except Exception:
        pass

def heartbeat_loop():
    """Periodic heartbeat for live monitoring."""
    while True:
        if state.get("running") and state.get("url"):
            ts = datetime.now().isoformat(timespec="seconds")
            push(watcher.last_value or 1, ts, event_override="HEARTBEAT")
        time.sleep(HEARTBEAT_SEC)

threading.Thread(target=heartbeat_loop, daemon=True).start()

class StartCfg(BaseModel):
    url: str | None = None

@app.get("/health")
def health():
    val = state["value"]
    meaning = (
        "BLOCKED" if val == 0 else ("CLEAR" if val == 1 else None)
    )
    return {
        "ok": True,
        "running": state["running"],
        "value": int(val) if val is not None else None,
        "meaning": meaning,
        "last_event": state["last_event"],
        "url": state["url"],
        "pin": PIN,
        "device": DEVICE,
    }

@app.post("/start")
def start(cfg: StartCfg):
    if cfg.url is not None:
        state["url"] = cfg.url
    if state["running"]:
        return {"running": True, "url": state["url"]}
    watcher.start(lambda v, ts: push(v, ts))
    state["running"] = True
    push(watcher.last_value, watcher.last_event_ts)  # initial state
    return {"running": True, "url": state["url"]}

@app.post("/stop")
def stop():
    watcher.stop()
    state["running"] = False
    return {"running": False}
