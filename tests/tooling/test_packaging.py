"""Check release integrity, executable permissions, architecture and reproducibility."""

import hashlib
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from package_release import package


class ReleasePackagingTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.binary = self.root / "game"
        header = bytearray(64)
        header[:6] = b"\x7fELF\x02\x01"
        header[16:20] = b"\x02\x00\x3e\x00"
        self.binary.write_bytes(header)
        self.license = self.root / "LICENSE"
        self.license.write_text("sample license\n")
        self.output = self.root / "dist"
        self.commit = "a" * 40

    def build(self, output=None, version="v0.1.0"):
        return package(
            self.binary, self.license, output or self.output, version, self.commit, 1700000000
        )

    def test_archive_contains_the_exact_executable_license_and_provenance(self):
        archive, standalone = self.build()
        self.assertEqual(standalone.read_bytes(), self.binary.read_bytes())
        self.assertEqual(standalone.stat().st_mode & 0o777, 0o755)
        with tarfile.open(archive) as bundle:
            prefix = "aetherium-v0.1.0-linux-x86_64/"
            self.assertEqual(
                set(bundle.getnames()),
                {
                    prefix + name
                    for name in (
                        "aetherium",
                        "README.txt",
                        "SOURCE_COMMIT",
                        "licenses/raylib-LICENSE.txt",
                    )
                },
            )
            self.assertEqual(bundle.getmember(prefix + "aetherium").mode, 0o755)
            self.assertEqual(
                bundle.extractfile(prefix + "aetherium").read(), self.binary.read_bytes()
            )
            self.assertEqual(
                bundle.extractfile(prefix + "SOURCE_COMMIT").read().decode().strip(), self.commit
            )
            self.assertEqual(
                bundle.extractfile(prefix + "licenses/raylib-LICENSE.txt").read(),
                self.license.read_bytes(),
            )

    def test_checksums_cover_both_downloadable_assets(self):
        assets = self.build()
        expected = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in assets}
        actual = {}
        for line in (self.output / "SHA256SUMS").read_text().splitlines():
            digest, name = line.split()
            actual[name] = digest
        self.assertEqual(actual, expected)

    def test_identical_inputs_produce_identical_archives(self):
        first, _ = self.build(self.root / "first")
        second, _ = self.build(self.root / "second")
        self.assertEqual(first.read_bytes(), second.read_bytes())

    def test_invalid_versions_cannot_write_paths_outside_the_release_directory(self):
        for version in ("../escape", "v0.1.0/../../escape", "", "latest"):
            with self.subTest(version=version), self.assertRaises(ValueError):
                self.build(version=version)
        self.assertFalse(self.output.exists())

    def test_wrong_architecture_and_non_elf_input_are_rejected(self):
        arm = bytearray(self.binary.read_bytes())
        arm[18:20] = b"\xb7\x00"
        for content in (b"not a program", arm):
            self.binary.write_bytes(content)
            with self.assertRaises(ValueError):
                self.build()
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
