# Modular NASM validation and performance

These are fresh measurements of the modular codebase. Earlier measurements
are archived in [history/pre-modular](history/pre-modular/PERFORMANCE.md) and
are not combined with this run.

## Correctness and maintainability checks

- 22 handwritten NASM modules with explicit dependencies.
- 98 named gameplay/ABI tests and 33,888 assertions, run separately against
  NASM and the original C reference without creating a window.
- 24 generator, translator and architectural boundary tests.
- 15,620 identical state/RNG records and 26 byte-identical rendered PNGs.
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

NASM 2.16.03, SSE2; C baseline uses `-O3 -ffp-contract=off -std=c99`.
Both versions link the same Raylib 5.5 and system libm. Eleven randomized
C/NASM pairs per workload, pinned to one CPU; calibration and warmup discarded.
Every timed pair also checks its final state hash.

| Workload | Paired speedup | NASM/C bootstrap 95% interval | Evidence |
| --- | ---: | --- | --- |
| spawn-zero | 1.71× | 0.568–0.602 | Faster |
| spawn-one | 1.02× | 0.967–0.987 | Faster |
| spawn-small | 1.06× | 0.926–0.967 | Faster |
| spawn-empty | 2.45× | 0.397–0.410 | Faster |
| spawn-dense | 30.72× | 0.032–0.033 | Faster |
| spawn-full | 141.53× | 0.007–0.007 | Faster |
| idle | 1.05× | 0.950–0.962 | Faster |
| normal | 1.30× | 0.761–0.776 | Faster |
| stress | 3.66× | 0.261–0.278 | Faster |
| vfx | 3.51× | 0.283–0.287 | Faster |
| render-title | 0.99× | 0.972–1.071 | Inconclusive |
| render-normal | 1.00× | 0.956–1.040 | Inconclusive |
| render | 0.99× | 0.976–1.044 | Inconclusive |

Normal simulation measured 1.30× faster and the crowded simulation measured 3.66× faster.
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
