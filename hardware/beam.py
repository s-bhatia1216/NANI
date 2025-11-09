# Reusable watcher class for the FastAPI agent.
import os, time, threading
from datetime import datetime
from typing import Callable, Optional

# Handle RPi.GPIO import for both development (macOS) and production (Raspberry Pi)
try:
    import RPi.GPIO as GPIO  # type: ignore
except ImportError:
    # Mock GPIO for development environments where RPi.GPIO is not available
    class MockGPIO:
        BCM = 11
        IN = 1
        PUD_UP = 22
        
        @staticmethod
        def setwarnings(flag: bool) -> None:
            pass
        
        @staticmethod
        def setmode(mode: int) -> None:
            pass
        
        @staticmethod
        def setup(pin: int, direction: int, pull_up_down: int = None) -> None:
            pass
        
        @staticmethod
        def input(pin: int) -> int:
            # Return 1 (CLEAR) as default for development
            return 1
        
        @staticmethod
        def cleanup(pin: int = None) -> None:
            pass
    
    GPIO = MockGPIO()  # type: ignore

class BeamWatcher:
    def __init__(self, pin: int = None, debounce: float = 0.02):
        self.pin = pin if pin is not None else int(os.getenv("PIN", "27"))
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
        # Your hardware: 0 = BLOCKED, 1 = CLEAR
        return "BLOCKED" if v == 0 else "CLEAR"

    def start(self, on_change: Optional[Callable[[int, str], None]] = None):
        if self._running:
            return
        self._running = True
        self.last_value = GPIO.input(self.pin)
        self.last_event_ts = datetime.now().isoformat(timespec="seconds")
        if on_change:
            on_change(self.last_value, self.last_event_ts)

        def loop():
            prev = self.last_value
            while self._running:
                v = GPIO.input(self.pin)
                if v != prev:
                    ts = datetime.now().isoformat(timespec="seconds")
                    self.last_value, self.last_event_ts = v, ts
                    if on_change:
                        on_change(v, ts)
                    prev = v
                time.sleep(self.debounce)

        self._thread = threading.Thread(target=loop, daemon=True)
        self._thread.start()

    def stop(self):
        self._running = False

    def cleanup(self):
        try:
            GPIO.cleanup(self.pin)
        except Exception:
            pass
