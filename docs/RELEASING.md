# Linux executable releases

Release tags use `vMAJOR.MINOR.PATCH`, starting with `v0.1.0` for the NASM port.
The tag must contain `.github/workflows/release.yml` and the intended game code.
Pushing it runs the build, complete correctness suite and C fixture sanitizers
on Ubuntu 24.04 before packaging or publishing.

`python3 tools/package_release.py --version v0.1.0` produces a standalone Linux x86-64
ELF executable, a gzip archive with executable permissions, controls, source
commit and Raylib license, plus `SHA256SUMS`. Tar metadata and gzip timestamps
are fixed so identical inputs produce identical archives. The packager rejects
non-x86-64 ELF inputs and malformed version names.

The workflow verifies checksums, extracts the archive and drives that exact
packaged executable with the real X11 keyboard smoke test. It uploads all assets
to a draft GitHub release, downloads them again and verifies their checksums,
then publishes only after those steps succeed. The
publish job has `contents: write` for release uploads; build CI retains its
existing permissions. Failed uploads can be retried while the release is a draft;
the workflow refuses to overwrite an already published release.

Runtime requirements are Linux x86-64, glibc 2.38+, X11/XWayland and OpenGL.
The package uses the included static Raylib library and system graphics libraries.
Do not advertise Windows, macOS or ARM artifacts without separate builds and tests.
