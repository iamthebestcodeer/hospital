> Historical measurements from the previous single-module layout; paths and fingerprints refer to that snapshot.

# Handwritten NASM performance and verification

Fresh measurements of this repository's handwritten gameplay build. All 45
entry points in `src/gameplay.asm` are written directly in NASM; rendering/UI
remains generated in `src/render.asm`. Particle allocation and VFX integration
use the supplied handwritten routines converted to NASM. Earlier measurements
of the compiler-generated gameplay version have been replaced.

## Functional verification

- 15,620 exact state/RNG records, including 1,408 particle allocation cases.
- 9,600 integrated simulation frames and 1,050 VFX frames.
- Six floating-text cases covering truncation/padding, pool replacement,
  no-allocation RNG behavior, and integer/FP varargs passed on the stack.
- Skill overlay remains open with points available and resumes play after the last point.
- 26 byte-identical PNG comparisons across game states and UI interactions.
- The playable executable accepts real X11 keys and exits cleanly on Escape.
- The C reference/harness passes ASan and UBSan; assembly memory behavior is
  covered by differential and boundary tests, not sanitizer instrumentation.

Reports: `verification.json` and `launch-smoke.json`. See
[../../../tests/COVERAGE.md](../../../tests/COVERAGE.md) for cases and exclusions.

## Timing results

CPU: AMD EPYC 9V74 80-Core Processor. Machine: x86_64.

C compiler: gcc (Debian 14.2.0-19) 14.2.0. C flags: `-O3 -ffp-contract=off -std=c99`.

Assembler: NASM 2.16.03, `-f elf64 -Werror`. Both versions link the same
Raylib 5.5 static library and system libm.

Eleven randomized C/NASM pairs per workload, pinned to one CPU. Calibration
and warmup are discarded. Times below are median microseconds per call/frame;
speedups and confidence intervals use paired samples, so dividing the two
independent median times may give a slightly different ratio.

| Workload | C µs | NASM µs | Paired speedup | NASM/C 95% interval | Evidence |
| --- | ---: | ---: | ---: | --- | --- |
| spawn-zero | 0.004 | 0.002 | 1.70× | 0.556–0.598 | Faster |
| spawn-one | 0.035 | 0.035 | 1.01× | 0.983–1.002 | Inconclusive |
| spawn-small | 0.278 | 0.270 | 1.04× | 0.917–1.003 | Inconclusive |
| spawn-empty | 20.142 | 8.375 | 2.40× | 0.409–0.425 | Faster |
| spawn-dense | 307.861 | 9.841 | 31.64× | 0.031–0.034 | Faster |
| spawn-full | 234.676 | 1.178 | 198.01× | 0.005–0.005 | Faster |
| idle | 2.311 | 2.356 | 0.99× | 0.995–1.032 | Inconclusive |
| normal | 8.229 | 6.339 | 1.30× | 0.763–0.795 | Faster |
| stress | 130.913 | 32.610 | 4.06× | 0.240–0.250 | Faster |
| vfx | 22.138 | 6.729 | 3.28× | 0.295–0.319 | Faster |
| render-title | 1563.197 | 1552.712 | 0.98× | 0.966–1.042 | Inconclusive |
| render-normal | 26754.678 | 27567.338 | 0.98× | 1.011–1.045 | Slower |
| render | 91269.550 | 89630.566 | 0.99× | 0.981–1.018 | Inconclusive |

A NASM/C ratio below 1 favors NASM. "Inconclusive" means the paired bootstrap
interval spans 1. Every timed pair has the same final state hash. All thirteen
workloads passed the predeclared coarse gate (no median slowdown over 5%).
That tolerance is not a claim of zero regression.

Normal simulation is 1.30× faster and crowded simulation is 4.06× faster.
The largest allocator gains occur in deliberately saturated pools and should
not be interpreted as whole-game FPS gains.

### Rendering follow-up

The initial eleven-pair normal-render run measured a 2.1% slowdown
(95% ratio interval 1.011–1.045). Rather than treating the 5% tolerance as
proof of no regression, this prompted an independent confirmation on the same
binaries, CPU, renderer and 30-frame workload:

| Confirmation | Pairs | B/A median | 95% ratio interval |
| --- | ---: | ---: | --- |
| Identical C versus C control | 16 | 0.9859 | 0.957–1.003 |
| NASM versus C | 32 | 1.0034 | 0.989–1.012 |

Execution order is exactly balanced and shuffled in each confirmation group.
The independent NASM/C result is 0.34% slower at the median, with an interval
spanning both faster and slower outcomes. It does **not** reproduce the initial
significant slowdown. The identical-C control also shows material run-to-run
variation. Rendering performance remains inconclusive; neither a rendering
speedup nor a universal zero-regression guarantee is established.

Raw confirmation samples, executable hashes and control measurements are in
`render-confirmation.json`. Reproduce with `make confirm-render`.

These finite measurements establish simulation improvements on this machine;
they cannot guarantee better performance for every frame, input sequence,
CPU, GPU, driver, or operating system. Rendering used Xvfb and Mesa software
OpenGL with one renderer thread, not a physical GPU. All effects, MSAA,
entity limits, damage rules, and UI behavior are retained.

## Workloads and reproduction

`spawn-zero`, `spawn-one`, and `spawn-small` request 0, 1, and 8 particles.
`spawn-empty` requests 250 particles with an empty pool; `spawn-dense` requests
250 with 2,750 occupied slots; `spawn-full` requests 200 with all 3,000 occupied.
Both versions preserve the same RNG stream and drop particles when full.

`idle` has no towers, enemies, or particles. `normal` has 12 towers, 60 enemies,
and 200 initial particles. `stress` has 100 towers, 300 enemies, and 2,500 initial
particles. `vfx` starts with 2,750 particles and adds periodic bursts. Frame
scenes include hero attacks, dash, and burst, and are rebuilt outside the timer
every 120 frames. `render-title`, `render-normal`, and `render` include full
DrawGame frames and graphics calls for title, normal, and crowded scenes.

Run `make test`, `make smoke`, and `make benchmark`. Raw timings, sample order,
state hashes, bootstrap intervals, and host details are in `benchmark.json`.
Use `tools/sanitizers.sh` for the C reference/harness ASan and UBSan check.

## Source fingerprints

- `reference/rpg.c`: `8bfd6336a2f99aaf89327b147ee0c6d0d51e7901100f8cc9196db282462a7255`
- `src/gameplay.asm`: `6590c8c09fd61717a624af37e93456a1ff115f73da731b681b3b6552905a6c16`
- `src/render.asm`: `9503de4be882238a1be2483a4fac8c6ebfe1d69f3fabd3f553ed6f04dc9e798a`
- `src/particles.asm`: `66e193edf34ac24e6e818cf56b065bfbeb21974a9c009f761cb205c043d002f7`
- `src/vfx.asm`: `29d66b87105390c22563186917ccf2e06f8d2a5dec109fa6c7fbfee8f6f26824`
- `src/abi.inc`: `1692ee637d459f6730af095e6417b6dd5b40f208348496712526a2a252872320`
- `src/layout.inc`: `ae61258e4db7b6d731786e01c2efb341e4659b5a78a2cd9d46df783b837539e0`
- `tests/harness.c`: `f5233dea5b693c4854c3beef052771680edd69b5f4484fa2b8f570f4986e5b87`
