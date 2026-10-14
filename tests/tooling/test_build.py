"""Check actual make scheduling in an isolated tree without compiling or touching the archive."""

from pathlib import Path
import os
import re
import shlex
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
ARCHIVE = "vendor/raylib-5.5_linux_amd64/lib/libraylib.a"
TARGETS = tuple(
    "build/" + name
    for name in (
        "aetherium",
        "rpg-c",
        "test-c",
        "test-asm",
        "unit-asm",
        "unit-c",
        "unit-sanitized",
        "integration-sanitized",
    )
)


class LinkDependencyTests(unittest.TestCase):
    def test_replacing_raylib_relinks_every_executable_exactly_once(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Makefile").write_bytes((ROOT / "Makefile").read_bytes())
            for name in ("src", "tests", "include", "reference"):
                (root / name).symlink_to(ROOT / name, target_is_directory=True)
            archive = root / ARCHIVE
            archive.parent.mkdir(parents=True)
            archive.touch()
            command = ["make", "-n", "NASM=" + os.environ.get("NASM", "nasm")]
            # Ask make for its expanded graph, then provide already-built objects.
            graph = subprocess.run(
                command + ["-p", *TARGETS],
                cwd=root,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True,
            ).stdout
            for name in set(re.findall(r"build/[A-Za-z0-9_./-]+\.o\b", graph)):
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.touch()
            (root / "build/reference-test.o").touch()
            for name in TARGETS:
                (root / name).touch()
            for target in TARGETS:
                with self.subTest(target=target):
                    before = subprocess.check_output(command + [target], cwd=root, text=True)
                    self.assertFalse(
                        any(line.startswith("gcc ") for line in before.splitlines()), before
                    )
                    after = subprocess.check_output(
                        command + ["-W", ARCHIVE, target], cwd=root, text=True
                    )
                    links = [
                        shlex.split(line)
                        for line in after.splitlines()
                        if line.startswith("gcc ") and line.endswith("-o " + target)
                    ]
                    self.assertEqual(len(links), 1, after)
                    self.assertEqual(links[0].count(ARCHIVE), 1, after)


if __name__ == "__main__":
    unittest.main()
