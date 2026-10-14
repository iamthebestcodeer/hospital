"""Run graphics tests on an existing X server or a temporary local Xvfb."""

from contextlib import contextmanager
from pathlib import Path
import os, shutil, subprocess, time

ROOT = Path(__file__).resolve().parents[1]


@contextmanager
def display():
    env = os.environ.copy()
    env["LIBGL_ALWAYS_SOFTWARE"] = "1"
    if env.get("DISPLAY"):
        yield env
        return
    binary = shutil.which("Xvfb") or str(ROOT / "vendor/xvfb/usr/bin/Xvfb")
    if not Path(binary).exists():
        raise RuntimeError("Install xvfb or set DISPLAY to an available X11 server.")
    number = 200 + os.getpid() % 10000
    env["DISPLAY"] = f":{number}"
    socket = Path(f"/tmp/.X11-unix/X{number}")
    Path("/tmp/.X11-unix").mkdir(exist_ok=True)
    with (ROOT / "build/xvfb-tests.log").open("w") as log:
        process = subprocess.Popen(
            [
                binary,
                env["DISPLAY"],
                "-screen",
                "0",
                "1280x800x24",
                "-ac",
                "-nolisten",
                "tcp",
                "-noreset",
            ],
            stdout=log,
            stderr=log,
        )
        try:
            for _ in range(100):
                if process.poll() is not None:
                    raise RuntimeError("Xvfb failed; see build/xvfb-tests.log")
                if socket.exists():
                    break
                time.sleep(0.05)
            else:
                raise RuntimeError("Xvfb startup timeout")
            yield env
        finally:
            process.terminate()
            process.wait(timeout=10)
