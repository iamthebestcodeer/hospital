#!/usr/bin/env python3
"""Observe real start/movement effects while driving the executable through X11."""

import argparse
import ctypes as C
from contextlib import contextmanager
import json
from pathlib import Path
import subprocess
import time
from common import ROOT, display


class XErrorEvent(C.Structure):
    _fields_ = [
        ("type", C.c_int),
        ("display", C.c_void_p),
        ("resourceid", C.c_ulong),
        ("serial", C.c_ulong),
        ("error_code", C.c_ubyte),
        ("request_code", C.c_ubyte),
        ("minor_code", C.c_ubyte),
    ]


XErrorHandler = C.CFUNCTYPE(C.c_int, C.c_void_p, C.POINTER(XErrorEvent))


class KeyboardDisplay:
    def __init__(self, name, title_prefix=b"Aetherium Vanguard"):
        self.title_prefix = title_prefix
        self.x11 = C.CDLL("libX11.so.6")
        self.xtst = C.CDLL("libXtst.so.6")
        signatures = {
            "XOpenDisplay": ([C.c_char_p], C.c_void_p),
            "XCloseDisplay": ([C.c_void_p], C.c_int),
            "XFlush": ([C.c_void_p], C.c_int),
            "XSync": ([C.c_void_p, C.c_int], C.c_int),
            "XSetErrorHandler": ([C.c_void_p], C.c_void_p),
            "XStringToKeysym": ([C.c_char_p], C.c_ulong),
            "XKeysymToKeycode": ([C.c_void_p, C.c_ulong], C.c_ubyte),
            "XDefaultRootWindow": ([C.c_void_p], C.c_ulong),
            "XQueryTree": (
                [
                    C.c_void_p,
                    C.c_ulong,
                    C.POINTER(C.c_ulong),
                    C.POINTER(C.c_ulong),
                    C.POINTER(C.POINTER(C.c_ulong)),
                    C.POINTER(C.c_uint),
                ],
                C.c_int,
            ),
            "XFetchName": ([C.c_void_p, C.c_ulong, C.POINTER(C.c_char_p)], C.c_int),
            "XFree": ([C.c_void_p], C.c_int),
            "XSetInputFocus": ([C.c_void_p, C.c_ulong, C.c_int, C.c_ulong], C.c_int),
            "XGetImage": (
                [C.c_void_p, C.c_ulong, C.c_int, C.c_int, C.c_uint, C.c_uint, C.c_ulong, C.c_int],
                C.c_void_p,
            ),
            "XGetPixel": ([C.c_void_p, C.c_int, C.c_int], C.c_ulong),
            "XDestroyImage": ([C.c_void_p], C.c_int),
        }
        for symbol, (args, result) in signatures.items():
            function = getattr(self.x11, symbol)
            function.argtypes, function.restype = args, result
        self.xtst.XTestFakeKeyEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
        self.connection = self.x11.XOpenDisplay(name.encode())
        assert self.connection, "Could not open X display"
        self.window = None

    def children(self, window):
        parent, returned_root, count = C.c_ulong(), C.c_ulong(), C.c_uint()
        children = C.POINTER(C.c_ulong)()
        if not self.x11.XQueryTree(
            self.connection,
            window,
            C.byref(returned_root),
            C.byref(parent),
            C.byref(children),
            C.byref(count),
        ):
            return []
        try:
            return list(children[: count.value])
        finally:
            self.x11.XFree(children)

    @contextmanager
    def _allow_disappearing_windows(self):
        # Xlib's error handler is process-wide. Drain earlier errors and scope
        # this exception narrowly to our connection's tree/name lookup requests.
        self.x11.XSync(self.connection, 0)
        unexpected = []

        @XErrorHandler
        def handle(display, event):
            error = event.contents
            if (
                display == self.connection
                and error.error_code == 3
                and error.request_code in (15, 20)
            ):
                return 0  # BadWindow from XQueryTree / XFetchName's GetProperty.
            if previous:
                return XErrorHandler(previous)(display, event)
            unexpected.append((error.error_code, error.request_code))
            return 0

        previous = self.x11.XSetErrorHandler(C.cast(handle, C.c_void_p))
        try:
            yield
        finally:
            # Keep the ctypes callback alive until all lookup errors arrive.
            try:
                self.x11.XSync(self.connection, 0)
            finally:
                self.x11.XSetErrorHandler(previous)
        if unexpected:
            raise RuntimeError(f"Unexpected X11 lookup errors: {unexpected}")

    def find_window(self):
        with self._allow_disappearing_windows():
            return self._find_window()

    def _find_window(self):
        root = self.x11.XDefaultRootWindow(self.connection)
        # Inspect clients before their frames: some WMs copy the client's title.
        pending = [(window, False) for window in self.children(root)]
        self.window = None
        while pending:
            window, inspected_children = pending.pop()
            if not inspected_children:
                pending.append((window, True))
                pending.extend((child, False) for child in self.children(window))
                continue
            title = C.c_char_p()
            if self.x11.XFetchName(self.connection, window, C.byref(title)):
                try:
                    if title.value and title.value.startswith(self.title_prefix):
                        self.window = window
                        return window
                finally:
                    self.x11.XFree(title)
        return None

    def hero_position(self):
        # Only the hero is purple in this part of the initial gameplay area.
        # Sample its filled circle, excluding the sidebar, title and particles.
        image = self.x11.XGetImage(
            self.connection, self.window, 40, 40, 460, 120, C.c_ulong(-1).value, 2
        )
        assert image, "Could not capture game window"
        points = []
        try:
            for y in range(0, 120, 2):
                for x in range(0, 460, 2):
                    pixel = self.x11.XGetPixel(image, x, y)
                    r, g, b = (pixel >> 16) & 255, (pixel >> 8) & 255, pixel & 255
                    if r > 80 and r > g * 1.3 and b > r * 1.15:
                        points.append((x + 40, y + 40))
        finally:
            self.x11.XDestroyImage(image)
        if len(points) < 60:
            return None
        return [sum(p[axis] for p in points) / len(points) for axis in (0, 1)]

    @contextmanager
    def held(self, key):
        code = self.x11.XKeysymToKeycode(self.connection, self.x11.XStringToKeysym(key.encode()))
        assert code
        assert self.xtst.XTestFakeKeyEvent(self.connection, code, 1, 0)
        self.x11.XFlush(self.connection)
        try:
            yield
        finally:
            self.xtst.XTestFakeKeyEvent(self.connection, code, 0, 0)
            self.x11.XFlush(self.connection)

    def tap(self, key):
        with self.held(key):
            time.sleep(0.12)
        time.sleep(0.08)

    def close(self):
        self.x11.XCloseDisplay(self.connection)


def wait_for(process, observe, message, timeout=8):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        assert process.poll() is None, "Game exited before " + message
        result = observe()
        if result:
            return result
        time.sleep(0.05)
    raise AssertionError(message)


def run(executable):
    (ROOT / "results").mkdir(exist_ok=True)
    actions = ["Return", "d", "q", "e", "space", "n", "g", "p", "p", "Escape"]
    with display() as env, (ROOT / "results/launch-smoke.log").open("w") as log:
        process = subprocess.Popen([executable], env=env, stdout=log, stderr=log)
        keyboard = KeyboardDisplay(env["DISPLAY"])
        try:
            window = wait_for(process, keyboard.find_window, "Game window never appeared")
            time.sleep(0.5)
            keyboard.x11.XSetInputFocus(keyboard.connection, window, 2, 0)
            keyboard.x11.XFlush(keyboard.connection)
            assert keyboard.hero_position() is None, "Expected the initial title screen"
            keyboard.tap("Return")
            start = wait_for(
                process, keyboard.hero_position, "Enter did not start gameplay: hero never appeared"
            )
            assert abs(start[0] - 100) < 6 and abs(start[1] - 100) < 6, start

            def moved():
                position = keyboard.hero_position()
                return position if position and position[0] > start[0] + 20 else None

            with keyboard.held("d"):
                after = wait_for(process, moved, "D did not move the hero to the right")
            assert abs(after[1] - start[1]) < 6, (start, after)
            for key in actions[2:]:
                keyboard.tap(key)
            status = process.wait(timeout=10)
            assert status == 0, status
        finally:
            keyboard.close()
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=10)
    report = {
        "real_x11_keys": actions,
        "observed_start": "hero appeared at spawn",
        "hero_before_movement": start,
        "hero_after_movement": after,
        "observed_movement": "D moved hero right by more than 20 pixels",
        "exit_status": status,
    }
    (ROOT / "results/launch-smoke.json").write_text(json.dumps(report, indent=2) + "\n")
    print("PASS: real Enter started gameplay, D moved the hero, and Escape exited cleanly.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--executable", type=Path, default=ROOT / "run.sh")
    run(parser.parse_args().executable.resolve())
