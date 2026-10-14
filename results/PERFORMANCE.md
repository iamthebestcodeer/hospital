# Modular NASM validation and performance

These are fresh measurements of the modular codebase. Earlier measurements
are archived in [history/pre-modular](history/pre-modular/PERFORMANCE.md) and
[history/pre-review](history/pre-review/PERFORMANCE.md), and are not combined
with this run. Both current implementations include the
[review corrections](../docs/REVIEW_FIXES.md).

## Correctness and maintainability checks

- 22 handwritten NASM modules with explicit dependencies.
- 101 named gameplay/ABI tests and 34,439 assertions, run separately against
  NASM and the corrected Linux C reference without creating a window.
- 27 generator, translator and architectural boundary tests.
- 15,620 identical state/RNG records and 26 byte-identical rendered PNGs.
- 28 asserted inspector clicks covering upgrades, gap and sell controls.
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
| spawn-zero | 2.02× | 0.479–0.518 | Faster |
| spawn-one | 1.02× | 0.855–0.996 | Faster |
| spawn-small | 1.04× | 0.946–0.977 | Faster |
| spawn-empty | 2.42× | 0.405–0.414 | Faster |
| spawn-dense | 31.38× | 0.031–0.033 | Faster |
| spawn-full | 204.10× | 0.005–0.005 | Faster |
| idle | 1.07× | 0.917–0.944 | Faster |
| normal | 1.31× | 0.751–0.781 | Faster |
| stress | 4.15× | 0.239–0.246 | Faster |
| vfx | 3.40× | 0.283–0.302 | Faster |
| render-title | 1.00× | 0.930–1.051 | Inconclusive |
| render-normal | 1.04× | 0.915–1.012 | Inconclusive |
| render | 1.02× | 0.962–1.013 | Inconclusive |

Normal simulation measured 1.31× faster and the crowded simulation measured 4.15× faster.
All 13 workloads passed the predeclared coarse gate (no median slowdown
exceeding 5%). A ratio below 1 favors NASM. Intervals spanning 1 are
inconclusive. Full-frame rendering remains within measurement uncertainty;
these measurements do not establish a graphics speedup or a universal
zero-regression guarantee. The 5% gate is a tolerance, not a proof of equality.

Rendering used Xvfb/Mesa software OpenGL with one renderer thread. Physical
GPUs, CPU frequency, drivers and host load can change results. Saturated
particle pools deliberately stress allocation; their speedups are not whole-game
FPS improvements. Scenes retain effects, MSAA, limits and gameplay rules.

## Reproduce

`make check`, `make sanitize`, `make format-check`, and `make benchmark`.
Use `make confirm-render` for balanced rendering measurements with an identical-C
control when a rendering result needs investigation. Raw paired timings,
order, state hashes, machine details and confidence intervals are in
[benchmark.json](benchmark.json). Workload definitions remain in
`tests/integration/harness.c` and the benchmark runner.
