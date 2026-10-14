"""Exercise discovery on real root-level and reparented X11 windows."""

import ctypes as C
import os
import unittest
from common import display
from smoke import KeyboardDisplay


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


if __name__ == "__main__":
    unittest.main()
