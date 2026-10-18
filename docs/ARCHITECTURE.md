# Architecture

The code follows Clean Code principles within a NASM/C ABI: one responsibility
per module, explicit dependencies, small shared mechanisms, observable behavior,
and tests at the public boundary. It keeps the existing game's behavior rather
than adding a new engine or an object-oriented framework.

## Ownership and boundaries

`src/domain` owns deterministic rules. It has no window, input, drawing, random
number, or gameplay-system imports. A tooling test enforces this boundary.
Geometry and damage operate on explicit arguments. Catalog/stat calculations
operate on a tower pointer. The map and enemy handles read the shared state.

`src/gameplay` owns orchestration for each feature: building, targeting,
progression, waves, spawning, movement, weapons and effects. Dependencies are
listed with `extern` at the top of each object. Functions retain their original
C ABI names, allowing the same tests to link either NASM or the reference C.
`av_` names identify internal assembly interfaces, such as handle validation.

`src/application/session.asm` owns initialization and game-state dispatch.
`src/platform/main.asm` owns the window lifetime and frame loop.
`src/platform/input.asm` translates screen coordinates and input into game actions.
Input/RNG/platform ports retain the Raylib-compatible ABI. Tests replace input
ports at link time and supply renderer doubles. They do not mock damage,
collision, progression, random-number generation, or entity updates.

`src/generated/render.asm` owns only rendering/UI and display lookups. Gameplay
unit executables do not link this object. Integration tests link the real
renderer and compare screenshots against the C implementation.

## Explicit compatibility tradeoff

The `game` storage object is defined once in `src/domain/state.asm`. It remains
shared to preserve compatibility with the original C layouts and renderer.
This is an intentional limit: the engine is not yet a reentrant, context-based
library. Keeping that constraint explicit avoids pretending that moving files
alone removes state coupling. A future context-pointer change requires an ABI
migration and new multi-instance tests.

`include/aetherium.h` defines the shared layout, including Raylib-compatible
Vector2/Color types. Compiler probes produce offsets in `src/include/abi.inc`
and `layout.inc`; assembly never guesses struct padding. Domain assembly does
not include Raylib headers or call its APIs.

## Assembly contracts

- System V AMD64 calling convention; SSE2 baseline; no fast-math.
- Stack aligned to 16 bytes before calls; callee-saved registers preserved.
- XMM registers are caller-saved. Values needed after another module's call
  must be spilled or recomputed. Unit tests deliberately clobber XMM4 at a
  catalog call and probe RBX/RBP/R12–R15 directly across game entry points.
  Deliberately broken callees verify each register check.
- Local labels and constants belong to their object. Small immutable constants
  may repeat between objects to avoid a shared mutable/global constant module.
- State layouts and RNG order are behavioral contracts. Pools retain their
  limits, lowest-free-slot allocation, and full-pool behavior.
- Executable-stack markers are forbidden by an architecture test.

The tower catalog is a leaf implementation. XP removes `pow` for its two reachable
exponents, retaining a double multiply for level 2 under the caller's rounding
mode; SSE2 scales the three floating-point stat lanes together.
The adjacent integer damage-type lane is masked before floating arithmetic and
restored by an integer store. Assembly-time offset checks protect this record
assumption. Prices use immutable lookup tables. See the
[catalog optimization assessment](../results/CATALOG_PERFORMANCE.md) for parity
coverage, measurements and the alternatives considered.

## Generated code

`tools/generate.py` is a CLI with importable pure extraction/validation helpers.
Importing it does not compile or write files. It discovers handwritten exports,
removes their C bodies from a temporary translation unit, and rejects any
non-rendering export from the generated assembly. Nested scopes, comments,
string literals, compound literals, and malformed input have focused tests.

The original `reference/rpg.c` is immutable provenance.
`tools/reference_fixes.py` applies explicit, guarded corrections to build
`reference/linux.c`; that corrected source also supplies rendering generation.
Unexpected upstream text fails generation rather than silently dropping a fix.
See [review fixes](REVIEW_FIXES.md) for intentional differences from upstream.

Normal builds assemble checked-in NASM directly. Code generation is an explicit
maintenance operation, not a hidden build step.
