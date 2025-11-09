# A simple local logger for testing and CSV recording.

# written on the Raspberry Pi running Raspbian.
import os, time, csv
import RPi.GPIO as GPIO
from datetime import datetime

PIN = int(os.getenv("PIN", "27"))            # GPIO number (BCM)
DEBOUNCE_SEC = float(os.getenv("DEBOUNCE", "0.02"))
LOGFILE = os.getenv("LOGFILE", "beam_events.csv")

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)

def now():
    return datetime.now().isoformat(timespec="seconds")

def label(v: int) -> str:
    # Your hardware: 0 = BLOCKED, 1 = CLEAR
    return "BLOCKED" if v == 0 else "CLEAR"

def append_csv(ts, value):
    try:
        new_file = not os.path.exists(LOGFILE)
        with open(LOGFILE, "a", newline="") as f:
            w = csv.writer(f)
            if new_file:
                w.writerow(["timestamp", "value", "meaning", "pin"])
            w.writerow([ts, value, label(value), PIN])
    except Exception:
        pass

print(f"[{now()}] Watching GPIO{PIN} (0=BLOCKED, 1=CLEAR). Ctrl+C to stop.")
prev = GPIO.input(PIN)
append_csv(now(), prev)
print(f"[{now()}] start -> {prev} ({label(prev)})")

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
    pass
finally:
    GPIO.cleanup(PIN)
