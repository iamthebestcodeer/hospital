# Testing strategy

Use a short feedback loop while changing a rule, then run the full behavior and
performance checks before calling a refactor complete.

| Command | Scope | Needs an X display? |
| --- | --- | --- |
| `make test-unit` | 98 named behavior tests / 33,888 assertions, run against both NASM and C | No |
| `make test-tools` | 24 translator, generator and architecture tests | No |
| `make test-integration` | 15,620 exact state/RNG records, 26 exact PNGs | Xvfb or `DISPLAY` |
| `make smoke` | Shipping executable, real X11 key events, clean shutdown | Xvfb or `DISPLAY` |
| `make check` | All tests above | Xvfb or `DISPLAY` |
| `make sanitize` | C unit/reference and integration memory/undefined-behavior checks | No |
| `make benchmark` | 13 randomized paired C/NASM workloads with state hashes | Xvfb or `DISPLAY` |
| `make confirm-render` | Balanced render samples plus an identical-C control | Xvfb or `DISPLAY` |

## Focused gameplay tests

Every named test receives a fresh game state and fixed random seed. Names state
the behavior. Checks stay active at `-O3` and print the failing test, condition,
source line, and actual/expected float values. The runner exits nonzero on the
first failure. Fixtures control input and supply renderer ports; gameplay and
Raylib RNG remain real.

- Geometry: board-wide tile round trips, negative floor boundaries, projections,
  angle wrap, build bounds and enemy handles.
- Damage/statuses: resistance types, minimum damage, negative armor, synergies,
  monotonic damage across 10,100 armor values, strongest-wins refresh, boss
  resistance, pool capacity, expiration and DoT.
- Towers/progression: all catalog costs and upgrade paths, build/sell resource
  conservation across every buildable tile, exhausted pools, targeting modes,
  stale handles, aim tolerance, XP thresholds, skills and leadership range.
- Session/hero/enemies: reset, title/pause/game-over/skill transitions, camera
  input translation, build tools, waves, movement normalization, dash/cooldowns,
  melee bounds, burst, healing, path overshoot and spawner deaths.
- Projectiles/effects: swept hits, stale IDs, weapon speeds, AoE bounds, chains,
  burn/melt synergy, pool saturation, lifetime boundaries, gravity and text ABI.
- ABI: mixed integer/FP overflow arguments, caller-saved XMM clobbering, and
  callee-saved register sentinels around nested calls.

The same suite runs against original C to catch incorrect test assumptions.
It independently checks expected rules; it does not merely compare two hashes.

## Differential and rendering tests

`tests/integration/harness.c` retains the existing seeded feature scenarios and
long simulations. `tests/verify.py` compares state and RNG output byte for byte,
then renders 26 states/UI scenarios and compares PNG bytes. These tests catch
changes in field values, operation order, random consumption, and draw output
that focused assertions might miss. `tests/COVERAGE.md` records the scenarios.

## Tooling and architecture tests

Python standard-library unittest tests validate parser boundaries, exact string
and float data, unknown-directive rejection, label scope, relocation conventions,
render-only generation, module ownership, and allowed domain imports. A translated
RIP-relative/alias fixture is assembled, linked and executed with real NASM/GCC.
The toolchain is required in CI; missing tools cause that one local test to skip.

## Limits

ASan/UBSan instrument the C reference and test fixtures, not NASM instructions.
Assembly safety is checked through boundary tests, guard behavior and exact state
comparisons. No finite suite proves all input sequences, NaN payloads, drivers or
hardware. Benchmarks save raw paired samples and distinguish simulation work from
full-frame rendering and measurement uncertainty. Performance thresholds are not
substitutes for reporting observed slowdowns.
