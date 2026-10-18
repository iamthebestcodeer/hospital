#!/usr/bin/env python3
"""Package a ready-to-run Linux x86-64 executable with provenance and checksums."""

import argparse
import gzip
import hashlib
import io
from pathlib import Path
import re
import subprocess
import struct
import tarfile

ROOT = Path(__file__).resolve().parents[1]


def package(binary, license_file, output, version, commit, epoch):
    """Validate an ELF input and write deterministic release assets and checksums."""
    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", version):
        raise ValueError("Version must be a release tag such as v0.1.0")
    executable = binary.read_bytes()
    if (
        len(executable) < 64
        or executable[:7] != b"\x7fELF\x02\x01\x01"
        or struct.unpack_from("<HHI", executable, 16) not in ((2, 62, 1), (3, 62, 1))
        or struct.unpack_from("<H", executable, 52)[0] != 64
    ):
        raise ValueError("Release binary must be a little-endian x86-64 ELF executable")
    directory = f"aetherium-{version}-linux-x86_64"
    readme = f"""Aetherium Vanguard NASM {version} — Linux x86-64

Run ./aetherium from this directory. No compiler, NASM, or build step is needed.
Requires Linux x86-64, glibc 2.38+, X11/XWayland and an OpenGL-capable desktop.
Runtime libraries: libGL, libX11, libXcursor, libXrandr, libXinerama and libXi.
Run the game as your normal user.

Controls: Enter starts; WASD moves; Space attacks; Q dashes; E bursts.
1–4 chooses a tower, left click places/selects, right click cancels.
Shift keeps the build tool selected; N starts a wave; G toggles the grid.
P pauses, R restarts after game over, and Escape exits.

Source: https://github.com/iamthebestcodeer/hospital/tree/{version}
Commit: {commit}
Raylib's license is included in licenses/raylib-LICENSE.txt.
"""
    files = {
        "aetherium": (executable, 0o755),
        "README.txt": (readme.encode(), 0o644),
        "SOURCE_COMMIT": ((commit + "\n").encode(), 0o644),
        "licenses/raylib-LICENSE.txt": (license_file.read_bytes(), 0o644),
    }
    output.mkdir(parents=True, exist_ok=True)
    standalone = output / "aetherium-linux-x86_64"
    standalone.write_bytes(executable)
    standalone.chmod(0o755)
    archive = output / (directory + ".tar.gz")
    with archive.open("wb") as destination:
        with gzip.GzipFile(filename="", fileobj=destination, mode="wb", mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w") as bundle:
                for name, (content, mode) in files.items():
                    entry = tarfile.TarInfo(directory + "/" + name)
                    entry.size, entry.mode, entry.mtime = len(content), mode, epoch
                    entry.uid = entry.gid = 0
                    entry.uname = entry.gname = "root"
                    bundle.addfile(entry, io.BytesIO(content))
    assets = (archive, standalone)
    (output / "SHA256SUMS").write_text(
        "".join(
            f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n" for path in assets
        )
    )
    (output / "RELEASE_NOTES.md").write_text(
        f"""Linux x86-64 binaries for Aetherium Vanguard NASM {version}.

Download **{archive.name}**, extract it, and run `./aetherium` inside the extracted directory. The archive includes the executable, controls, source commit and Raylib license; no build tools are required. The separate **aetherium-linux-x86_64** asset is the same executable; after downloading it, run `chmod +x aetherium-linux-x86_64` and `./aetherium-linux-x86_64`.

Requires **Linux x86-64, glibc 2.38+, X11/XWayland and OpenGL** (for example, Ubuntu 24.04+ or Debian 13+). Run as a normal user. This release does not include Windows, macOS or ARM builds.

Includes the gameplay, rendering and desktop smoke-test fixes reviewed in PR #2. Gameplay is handwritten NASM; rendering/UI remains generated assembly. Validation covers unit tests, exact C/NASM state and image comparisons, X11 input/window races, and C fixture sanitizers. Graphics validation uses Mesa software rendering; physical GPU/driver combinations vary.

Verify downloads with `sha256sum --check --ignore-missing SHA256SUMS` after downloading the checksum file and your chosen binary asset into the same directory.

Source commit: `{commit}`.
"""
    )
    return assets


def main():
    """Package the selected binary using the current Git commit as provenance."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    parser.add_argument("--binary", type=Path, default=ROOT / "build/aetherium")
    args = parser.parse_args()
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    epoch = int(subprocess.check_output(["git", "show", "-s", "--format=%ct", "HEAD"], cwd=ROOT))
    for path in package(
        args.binary,
        ROOT / "vendor/raylib-5.5_linux_amd64/LICENSE",
        args.output,
        args.version,
        commit,
        epoch,
    ):
        print(path)


if __name__ == "__main__":
    main()
