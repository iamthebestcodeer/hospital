# Aetherium Vanguard — Linux NASM

A tower-defense RPG hybrid with handwritten x86-64 NASM gameplay and Raylib 5.5.
The game preserves the supplied C version's rules, visuals and entity limits.
Rendering/UI remains generated assembly; rewriting it by hand is the next major
stage in [the handwritten plan](docs/HANDWRITTEN_PLAN.md).

## Build and play

Requires x86-64 Linux, glibc 2.38+, NASM 2.16+, GCC, GNU binutils, Make, and an
X11/XWayland desktop with OpenGL. On Debian 13 / Ubuntu 24.04 or newer:

```sh
sudo apt-get install nasm build-essential libgl1 libx11-6 libxcursor1 libxrandr2 libxinerama1 libxi6
make
./run.sh
```

Raylib headers and its static library are included. Normal builds need no
network, Python, or C gameplay compilation. Only assembly is built and linked.
The executable is `build/aetherium`.

## Development and tests

```sh
sudo apt-get install python3 xvfb libxtst6
make test-unit       # Fast headless gameplay tests against NASM and C
make test-tools      # Translator, generator and architecture contracts
make test-integration # 15,620 exact state/RNG records and 26 PNG comparisons
make check           # All of the above plus real X11 keyboard smoke tests
make sanitize        # C reference, unit fixtures and integration harness: ASan/UBSan
make benchmark       # Paired performance measurements against optimized C
```

Unit tests link handwritten gameplay without the renderer and use explicit
input/rendering test doubles. Both implementations run the same behavioral
suite. Tests cover business rules, invalid inputs, exhausted pools, targeting,
resource conservation, coordinate properties, state transitions, variadic ABI
handling, and register preservation. Graphics tests use `DISPLAY` or start and
stop their own Xvfb instance. See [testing](docs/TESTING.md) for details.

Formatting tools are optional for building, required for contributing:

```sh
python3 -m pip install -r requirements-dev.txt
make format
make format-check
```

## Code map

| Directory | Responsibility |
| --- | --- |
| `src/domain/` | Deterministic geometry, map, damage, status, catalog and handle rules |
| `src/gameplay/` | Hero, enemies, towers, projectiles, progression, waves and effects |
| `src/application/` | Session initialization and game-state transitions |
| `src/platform/` | Window/frame loop and mouse/keyboard translation |
| `src/generated/` | Generated rendering/UI NASM, clearly separated from handwritten code |
| `src/include/` | Assembly ABI offsets and shared calling-convention macros |
| `include/aetherium.h` | Generated public C ABI contract used by the test harnesses |
| `tests/unit/` | Named headless behavioral tests, fixtures and ABI probes |
| `tests/tooling/` | Generator/translator tests and architectural dependency checks |
| `tests/integration/` | Differential scenarios, rendering fixtures and benchmark driver |
| `reference/` | Preserved original C source and its Linux compatibility version |

Each assembly module declares its dependencies explicitly and builds into its
own object. Build dependencies track included headers and assembly includes.
Read [architecture](docs/ARCHITECTURE.md) and [contributing](docs/CONTRIBUTING.md)
before changing a module.

## Controls

| Input | Action |
| --- | --- |
| Enter / click | Start |
| WASD / Space | Move / attack |
| Q / E | Dash / Aether Burst |
| 1–4 / sidebar | Choose tower |
| Left click / right click | Place or select / cancel |
| Shift while placing | Keep the build tool selected |
| N / G / P | Next wave / grid / pause |
| R after game over / Escape | Restart / exit |

Tower inspectors retain targeting modes, specialization upgrades and selling.
All four hero skills, twelve tower types, eight enemy types, status synergies,
procedural waves, lighting, tooltips, particles and screen shake remain.
Limits are 100 towers, 300 enemies, 500 projectiles, 3,000 particles, and
100 floating texts.

## Generated files, provenance and measurements

`make regenerate` updates rendering assembly, ABI offsets and the C test header.
It discovers handwritten exports and removes their C definitions before
translation. A whitelist rejects generated gameplay exports. Handwritten modules
are never outputs of the generator. GCC 14.2 was used for checked-in rendering;
other compiler versions may emit different rendering instructions.

The source was supplied in `aetherium-linux-x86_64.tar.gz` and identified by the
user as [this pinned Gist revision](https://gist.github.com/iamthebestcodeer/91949c5dfd28d9f29acbd027aaed77d8/596d6f2067973fdd7f5ff726ee2ce94a9f9253d5).
`reference/rpg.c` is unchanged. `reference/linux.c` exports the state for testing
and renames the rounded-outline fallback to avoid a Raylib symbol collision.
Raylib's license is in `vendor/raylib-5.5_linux_amd64/LICENSE`.

Current measurements and their limits are in [results/PERFORMANCE.md](results/PERFORMANCE.md).
Simulation improvements and rendering uncertainty are reported separately;
finite benchmarks cannot establish a universal zero-regression guarantee.
