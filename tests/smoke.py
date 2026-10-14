#!/usr/bin/env python3
"""Drive the shipping executable with real X11 keyboard events, not wrappers."""

import ctypes as C, json, subprocess, time
from common import ROOT, display

(ROOT / "results").mkdir(exist_ok=True)
x11 = C.CDLL("libX11.so.6")
xtst = C.CDLL("libXtst.so.6")
x11.XOpenDisplay.argtypes = [C.c_char_p]
x11.XOpenDisplay.restype = C.c_void_p
x11.XCloseDisplay.argtypes = [C.c_void_p]
x11.XFlush.argtypes = [C.c_void_p]
x11.XStringToKeysym.argtypes = [C.c_char_p]
x11.XStringToKeysym.restype = C.c_ulong
x11.XKeysymToKeycode.argtypes = [C.c_void_p, C.c_ulong]
x11.XKeysymToKeycode.restype = C.c_ubyte
xtst.XTestFakeKeyEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
with display() as env:
    with (ROOT / "results/launch-smoke.log").open("w") as log:
        p = subprocess.Popen([ROOT / "run.sh"], env=env, stdout=log, stderr=log)
        d = x11.XOpenDisplay(env["DISPLAY"].encode())
        assert d
        actions = ["Return", "d", "q", "e", "space", "n", "g", "p", "p", "Escape"]
        try:
            time.sleep(1)
            assert p.poll() is None, "Game exited before accepting input"
            for key in actions:
                code = x11.XKeysymToKeycode(d, x11.XStringToKeysym(key.encode()))
                assert code
                assert xtst.XTestFakeKeyEvent(d, code, 1, 0)
                x11.XFlush(d)
                time.sleep(0.12)
                xtst.XTestFakeKeyEvent(d, code, 0, 0)
                x11.XFlush(d)
                time.sleep(0.08)
            status = p.wait(timeout=10)
            assert status == 0, status
        finally:
            x11.XCloseDisplay(d)
            if p.poll() is None:
                p.terminate()
                p.wait(timeout=10)
(ROOT / "results/launch-smoke.json").write_text(
    json.dumps({"real_x11_keys": actions, "exit_status": status}, indent=2) + "\n"
)
print("PASS: shipping executable accepted real X11 inputs and closed with status 0.")
