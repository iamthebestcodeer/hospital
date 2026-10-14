# Modular NASM validation and performance

The 13-workload measurements below were taken at commit `495f913`, before
the beam-visibility follow-up. A fresh balanced rendering check of the corrected
renderer is reported separately below. Earlier measurements
are archived in [history/pre-modular](history/pre-modular/PERFORMANCE.md) and
[history/pre-review](history/pre-review/PERFORMANCE.md) and
[history/pre-pr2-review](history/pre-pr2-review/PERFORMANCE.md), and are not combined
with this run. Both current implementations include the
[review corrections](../docs/REVIEW_FIXES.md).

## Correctness and maintainability checks

- 22 handwritten NASM modules with explicit dependencies.
- 104 named gameplay/ABI tests and 34,505 assertions, run separately against
  NASM and the corrected Linux C reference without creating a window.
- 28 generator, translator, architectural and build dependency tests.
- 15,620 identical state/RNG records and 26 byte-identical rendered PNGs.
- 28 asserted inspector clicks covering upgrades, gap and sell controls.
- Ten pixel-level Cryo/Freezer beam cases and seven actual X11 window-lookup/error tests.
- Real X11 input and clean exit of the shipping executable.
- C reference, C unit fixtures and integration harness passed ASan/UBSan.
- Formatting checks and regeneration checks passed; handwritten modules are
  unchanged by regeneration.
- An intentionally restored caller-saved XMM4 defect is rejected by the new
  aim-tolerance regression test. The fixed module spills the value across calls.

Full check metadata, module fingerprints and executable hashes are in
[validation.json](validation.json). Sanitizers instrument C code, not NASM;
assembly safety is checked through behavioral, boundary and differential tests.

## Paired performance measurements

CPU: AMD EPYC 9V74 80-Core Processor. Compiler: gcc (Debian 14.2.0-19) 14.2.0.

NASM 2.16.03, SSE2; Corrected C baseline uses `-O3 -ffp-contract=off -std=c99`.
Both versions link the same Raylib 5.5 and system libm. Eleven randomized
C/NASM pairs per workload, pinned to one CPU; calibration and warmup discarded.
Every timed pair also checks its final state hash.

| Workload | Paired speedup | NASM/C bootstrap 95% interval | Evidence |
| --- | ---: | --- | --- |
| spawn-zero | 1.61× | 0.488–0.722 | Faster |
| spawn-one | 1.05× | 0.848–1.072 | Inconclusive |
| spawn-small | 1.05× | 0.854–1.064 | Inconclusive |
| spawn-empty | 3.32× | 0.277–0.544 | Faster |
| spawn-dense | 32.54× | 0.024–0.032 | Faster |
| spawn-full | 196.85× | 0.005–0.006 | Faster |
| idle | 1.01× | 0.982–1.021 | Inconclusive |
| normal | 1.28× | 0.741–0.793 | Faster |
| stress | 4.05× | 0.238–0.257 | Faster |
| vfx | 3.18× | 0.306–0.322 | Faster |
| render-title | 0.94× | 0.948–1.118 | Inconclusive |
| render-normal | 1.01× | 0.956–1.029 | Inconclusive |
| render | 0.99× | 0.993–1.028 | Inconclusive |

Normal simulation measured 1.28× faster and crowded simulation 4.05× faster.
Twelve of thirteen workloads passed the predeclared 5% median regression gate.
The initial title-screen measurement exceeded it: NASM/C 1.060, with a wide
95% interval of 0.948–1.118. The initial benchmark command therefore failed;
its raw samples and regression flag are retained in [benchmark.json](benchmark.json).

A follow-up used 32 balanced NASM/C title-screen pairs and 16 identical-C control
pairs. NASM/C measured 0.978 (95% interval 0.952–1.004), while the identical-C
control measured 1.027 (0.920–1.069). The slowdown did not reproduce. Full-frame
rendering remains inconclusive; neither run proves a graphics speedup or a
universal zero-regression guarantee. The 5% gate is a tolerance, not proof of
equality. Follow-up samples, order, hashes and intervals are retained in
[historical title confirmation](history/pre-beam-fix/render-confirmation.json).


## Corrected beam-renderer follow-up

The current renderer was measured with 32 balanced NASM/C `render-normal` pairs
and 16 identical-C control pairs. NASM/C was 1.004 (95% interval 0.982–1.033);
the identical-C control was 0.999 (0.986–1.013). The median meets the 5% gate,
and the interval does not establish a rendering difference. Every pair's state
hash matched. The tested executable hashes and raw samples are in
[render-confirmation.json](render-confirmation.json). This follow-up does not
replace or hide the earlier title-screen gate miss.

Rendering used Xvfb/Mesa software OpenGL with one renderer thread. Physical
GPUs, CPU frequency, drivers and host load can change results. Saturated
particle pools deliberately stress allocation; their speedups are not whole-game
FPS improvements. Scenes retain effects, MSAA, limits and gameplay rules.

## Reproduce

`make check`, `make sanitize`, `make format-check`, and `make benchmark`.
Use `make confirm-render` for balanced default rendering measurements with an
identical-C control. To reproduce this title-screen investigation, run
`python3 tests/confirm_render.py --workload render-title` after building the test
executables. Raw paired timings,
order, state hashes, machine details and confidence intervals are in
[benchmark.json](benchmark.json). Workload definitions remain in
`tests/integration/harness.c` and the benchmark runner.
