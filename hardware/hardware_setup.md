# NANI on the Raspberry Pi: Beam Detection System

This document explains how to build, wire, and deploy the **IR beam-based medication detection system** on a Raspberry Pi.  
It covers everything from **hardware wiring** → **FastAPI setup** → **Google Sheets integration**.

---

## 1. Hardware Setup

### Components
- Raspberry Pi 3 Model B (or newer)
- IR Break-Beam pair (emitter + receiver)
- Breadboard + jumper wires
- 330 Ω resistor (for emitter current limiting)
- (Optional) 10 kΩ resistor (for external pull-up)
- USB power supply

### Wiring Summary

| Component | Wire Color | Connects To | Notes |
|------------|-------------|--------------|-------|
| **Emitter (IR LED)** | Red | 5 V → through **330 Ω resistor** → Emitter VCC | Limits LED current |
| | Black | GND | |
| **Receiver (Phototransistor)** | Red | 5 V | Power |
| | Black | GND | Common ground with Pi |
| | Yellow | GPIO 27 (physical pin 13) | Signal output to Pi |

> **Polarity:** Emitter’s longer leg is positive (+). Receiver’s OUT/DO pin is the digital signal.

**Logic Behavior:**  
`0 = BLOCKED` (beam interrupted)  
`1 = CLEAR` (beam aligned)

---

## 2. Raspberry Pi Setup

### Install base packages
```bash
sudo apt update
sudo apt install -y python3-pip python3-venv python3-rpi.gpio python3-fastapi python3-uvicorn python3-requests
```

### Project structure
```bash
/home/pi/nani/
├── beam_raw.py
├── beam.py
├── beam_api.py
└── NANI_Beam_Quick_Reference.md
```

---

## 3. Python Scripts

### beam_raw.py
Simple logger for local debugging and CSV output.

```python
import os, time, csv
import RPi.GPIO as GPIO
from datetime import datetime

PIN = int(os.getenv("PIN", "27"))
DEBOUNCE_SEC = float(os.getenv("DEBOUNCE", "0.02"))
LOGFILE = os.getenv("LOGFILE", "beam_events.csv")

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)

def now(): return datetime.now().isoformat(timespec="seconds")
def label(v: int) -> str: return "BLOCKED" if v == 0 else "CLEAR"

def append_csv(ts, value):
    new_file = not os.path.exists(LOGFILE)
    with open(LOGFILE, "a", newline="") as f:
        w = csv.writer(f)
        if new_file:
            w.writerow(["timestamp", "value", "meaning", "pin"])
        w.writerow([ts, value, label(value), PIN])

print(f"[{now()}] Watching GPIO{PIN} (0=BLOCKED, 1=CLEAR). Ctrl+C to stop.")
prev = GPIO.input(PIN)
append_csv(now(), prev)

try:
    while True:
        v = GPIO.input(PIN)
        if v != prev:
            ts = now()
            print(f"[{ts}] changed -> {v} ({label(v)})")
            append_csv(ts, v)
            prev = v
        time.sleep(DEBOUNCE_SEC)
except KeyboardInterrupt:
    GPIO.cleanup(PIN)
```

---

### beam.py
Encapsulates beam logic for re-use by the FastAPI service.

```python
import os, time, threading
import RPi.GPIO as GPIO
from datetime import datetime
from typing import Callable, Optional

class BeamWatcher:
    def __init__(self, pin: int = None, debounce: float = 0.02):
        self.pin = pin if pin else int(os.getenv("PIN", "27"))
        self.debounce = debounce
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self.last_value = None
        self.last_event_ts = None

        GPIO.setwarnings(False)
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)

    @staticmethod
    def meaning(v: int) -> str:
        return "BLOCKED" if v == 0 else "CLEAR"

    def start(self, on_change: Optional[Callable[[int, str], None]] = None):
        if self._running: return
        self._running = True
        self.last_value = GPIO.input(self.pin)
        self.last_event_ts = datetime.now().isoformat(timespec="seconds")
        if on_change: on_change(self.last_value, self.last_event_ts)

        def loop():
            prev = self.last_value
            while self._running:
                v = GPIO.input(self.pin)
                if v != prev:
                    ts = datetime.now().isoformat(timespec="seconds")
                    self.last_value, self.last_event_ts = v, ts
                    if on_change: on_change(v, ts)
                    prev = v
                time.sleep(self.debounce)

        self._thread = threading.Thread(target=loop, daemon=True)
        self._thread.start()

    def stop(self):
        self._running = False
        GPIO.cleanup(self.pin)
```

---

### beam_api.py
FastAPI service that sends beam data to Google Sheets or your backend.

```python
import os, requests, threading, time
from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
from beam import BeamWatcher

PIN = int(os.getenv("PIN", "27"))
DEFAULT_URL = os.getenv("URL", "")
DEVICE = os.getenv("DEVICE", "pi3-nani")
HEARTBEAT_SEC = int(os.getenv("HEARTBEAT", "30"))

app = FastAPI(title="NANI Beam API")
watcher = BeamWatcher(pin=PIN)
state = {"running": False, "value": None, "last_event": None, "url": DEFAULT_URL}

def push(value: int, ts: str, event_override=None):
    state["value"] = value
    state["last_event"] = ts
    url = state["url"]
    if not url: return
    event = event_override or ("BLOCKED" if value == 0 else "CLEAR")
    try:
        requests.post(url, json={
            "event": event,
            "value": int(value),
            "pin": PIN,
            "device": DEVICE,
            "ts": ts
        }, timeout=4)
    except Exception:
        pass

def heartbeat_loop():
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
    meaning = "BLOCKED" if val == 0 else ("CLEAR" if val == 1 else None)
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
    push(watcher.last_value, watcher.last_event_ts)
    return {"running": True, "url": state["url"]}

@app.post("/stop")
def stop():
    watcher.stop()
    state["running"] = False
    return {"running": False}
```

---

## ⚙️ 4. Systemd Autostart Service

Create `/etc/systemd/system/nani-beam-api.service`:

```ini
[Unit]
Description=NANI Beam API
After=network-online.target
Wants=network-online.target

[Service]
User=pi
WorkingDirectory=/home/pi/nani
ExecStart=/usr/bin/python3 -m uvicorn beam_api:app --host 0.0.0.0 --port 8080
Restart=always
RestartSec=2
Environment=PIN=27
Environment=DEVICE=pi3-nani
Environment=URL=https://script.google.com/macros/s/XXXXXXXXXXXXXXXXXXXX/exec
Environment=HEARTBEAT=30

[Install]
WantedBy=multi-user.target
```

Enable and start it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable nani-beam-api
sudo systemctl start nani-beam-api
```

---

## 5. Google Sheets Setup

### A) Create the Sheet
1. Open [Google Sheets](https://sheets.google.com) → create a sheet named **NANI Events**.

### B) Apps Script backend
1. In the sheet: **Extensions → Apps Script**.
2. Paste this code and save:

```javascript
function doPost(e) {
  const payload = e.postData && e.postData.contents ? JSON.parse(e.postData.contents) : {};
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sh = ss.getSheetByName('Events') || ss.insertSheet('Events');
  if (sh.getLastRow() === 0) {
    sh.appendRow(['timestamp','event','value','pin','device','ts_from_pi']);
  }
  sh.appendRow([new Date(), payload.event || '', payload.value ?? '', payload.pin ?? '', payload.device || '', payload.ts || '']);
  return ContentService.createTextOutput('OK').setMimeType(ContentService.MimeType.TEXT);
}
```

3. **Deploy → New deployment → Web app**  
   - Execute as: **Me**  
   - Who has access: **Anyone**  
   - Copy the Web App URL (ends with `/exec`).

4. Paste that URL in your Pi’s service file (`Environment=URL=...`).

---

## 6. Usage Summary

| Action | Command |
|---------|----------|
| **Check status** | `curl http://<PI_IP>:8080/health` |
| **Start manually** | `curl -X POST http://<PI_IP>:8080/start -H 'Content-Type: application/json' -d '{"url":"<YOUR_SCRIPT_URL>"}'` |
| **Stop** | `curl -X POST http://<PI_IP>:8080/stop` |
| **Logs** | `journalctl -u nani-beam-api -f` |

---

## 7. What Each Part Does

| Component | Purpose |
|------------|----------|
| **beam_raw.py** | Local debugging + CSV logging |
| **beam.py** | Handles GPIO beam reading logic |
| **beam_api.py** | FastAPI microservice that pushes events to the cloud |
| **Systemd service** | Auto-starts the API on boot |
| **Google Apps Script** | Receives JSON and logs data into Google Sheets |

---

### Final Logic Verification
- **0 → BLOCKED** → beam interrupted → logs “BLOCKED”  
- **1 → CLEAR** → beam aligned → logs “CLEAR”

All layers (hardware, Pi, API, and Sheets) now use the same interpretation.

---

© 2025 NANI Project — HackPrinceton F25 Submission
