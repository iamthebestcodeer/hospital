"""Exercise discovery on real root-level and reparented X11 windows."""

import ctypes as C
import os
import unittest
from unittest.mock import patch
from common import display
from smoke import KeyboardDisplay, XErrorHandler


class WindowLookupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = display()
        cls.env = cls.server.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.server.__exit__(None, None, None)

    def setUp(self):
        self.keyboard = KeyboardDisplay(
            self.env["DISPLAY"], title_prefix=f"aetherium-lookup-{os.getpid()}".encode()
        )
        self.x11 = self.keyboard.x11
        self.connection = self.keyboard.connection
        self.root = self.x11.XDefaultRootWindow(self.connection)
        self.x11.XCreateSimpleWindow.argtypes = [
            C.c_void_p,
            C.c_ulong,
            C.c_int,
            C.c_int,
            C.c_uint,
            C.c_uint,
            C.c_uint,
            C.c_ulong,
            C.c_ulong,
        ]
        self.x11.XCreateSimpleWindow.restype = C.c_ulong
        self.x11.XStoreName.argtypes = [C.c_void_p, C.c_ulong, C.c_char_p]
        self.x11.XReparentWindow.argtypes = [C.c_void_p, C.c_ulong, C.c_ulong, C.c_int, C.c_int]
        self.x11.XSync.argtypes = [C.c_void_p, C.c_int]
        self.x11.XDestroyWindow.argtypes = [C.c_void_p, C.c_ulong]

    def tearDown(self):
        self.keyboard.close()

    def create(self, parent, title):
        window = self.x11.XCreateSimpleWindow(self.connection, parent, 0, 0, 8, 8, 0, 0, 0)
        self.assertTrue(window)
        self.x11.XStoreName(self.connection, window, title)
        self.x11.XSync(self.connection, 0)
        return window

    def test_root_level_game_window_is_found(self):
        game = self.create(self.root, self.keyboard.title_prefix + b" game")
        self.assertEqual(self.keyboard.find_window(), game)

    def test_game_window_is_found_after_reparenting_into_nested_frames(self):
        game = self.create(self.root, self.keyboard.title_prefix + b" game")
        frame = self.create(self.root, self.keyboard.title_prefix + b" copied frame title")
        inner = self.create(frame, b"inner frame")
        self.x11.XReparentWindow(self.connection, game, inner, 0, 0)
        self.x11.XSync(self.connection, 0)
        self.assertEqual(self.keyboard.find_window(), game)

    def test_unrelated_windows_do_not_match(self):
        frame = self.create(self.root, b"unrelated app")
        self.create(frame, b"unrelated child")
        self.assertIsNone(self.keyboard.find_window())

    def test_popup_destroyed_after_queuing_does_not_abort_discovery(self):
        game = self.create(self.root, self.keyboard.title_prefix + b" game")
        popup = self.create(self.root, b"temporary popup")
        original_children = self.keyboard.children
        queried = []

        def children(window):
            queried.append(window)
            result = original_children(window)
            if window == self.root:
                self.x11.XDestroyWindow(self.connection, popup)
                self.x11.XSync(self.connection, 0)
            return result

        with patch.object(self.keyboard, "children", side_effect=children):
            self.assertEqual(self.keyboard.find_window(), game)
        self.assertIn(popup, queried)

    def test_popup_destroyed_before_name_fetch_does_not_abort_discovery(self):
        game = self.create(self.root, self.keyboard.title_prefix + b" game")
        popup = self.create(self.root, b"temporary popup")
        original_children = self.keyboard.children

        def children(window):
            result = original_children(window)
            if window == popup:
                self.x11.XDestroyWindow(self.connection, popup)
                self.x11.XSync(self.connection, 0)
            return result

        with patch.object(self.keyboard, "children", side_effect=children):
            self.assertEqual(self.keyboard.find_window(), game)

    def test_previous_error_handler_is_restored_after_success_and_failure(self):
        game = self.create(self.root, self.keyboard.title_prefix + b" game")
        errors = []

        @XErrorHandler
        def previous_handler(display, event):
            errors.append((display, event.contents.error_code, event.contents.request_code))
            return 0

        previous = self.x11.XSetErrorHandler(C.cast(previous_handler, C.c_void_p))
        try:
            for failed_lookup in (False, True):
                with self.subTest(failed_lookup=failed_lookup):
                    if failed_lookup:
                        with patch.object(
                            self.keyboard, "children", side_effect=RuntimeError("lookup failed")
                        ):
                            with self.assertRaisesRegex(RuntimeError, "lookup failed"):
                                self.keyboard.find_window()
                    else:
                        self.assertEqual(self.keyboard.find_window(), game)
                    # Outside lookup, BadWindow must reach the previous handler.
                    self.assertEqual(self.keyboard.children(0), [])
                    self.assertEqual(errors[-1], (self.connection, 3, 15))
            self.assertEqual(len(errors), 2)
        finally:
            self.x11.XSetErrorHandler(previous)

    def test_unrelated_requests_and_other_connections_keep_their_error_handler(self):
        errors = []

        @XErrorHandler
        def previous_handler(display, event):
            errors.append((display, event.contents.error_code, event.contents.request_code))
            return 0

        previous = self.x11.XSetErrorHandler(C.cast(previous_handler, C.c_void_p))
        other = KeyboardDisplay(self.env["DISPLAY"])
        try:
            with self.keyboard._allow_disappearing_windows():
                self.x11.XDestroyWindow(self.connection, 0)  # BadWindow, but not lookup.
                self.x11.XSync(self.connection, 0)
                other.children(0)  # Lookup on another display connection must not be masked.
            self.assertEqual(errors, [(self.connection, 3, 4), (other.connection, 3, 15)])
        finally:
            other.close()
            self.x11.XSetErrorHandler(previous)


if __name__ == "__main__":
    unittest.main()
