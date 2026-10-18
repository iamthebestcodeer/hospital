# Tower catalog optimization review

This change optimizes `src/domain/tower_catalog.asm` against its implementation
at `855442b0b225bb8b67d66de306a59693fcb9ef21`. The corrected C reference remains
unchanged. Raw measurements, sample order, matching state hashes, source and
executable fingerprints are in [catalog-benchmark.json](catalog-benchmark.json).

## Assessment of the five suggestions

| Suggestion | Finding and decision |
| --- | --- |
| Replace `pow` and make the function a leaf | Valid. Only types 0–3 below level 3 reach the XP formula. Nonpositive levels clamp to 1, so the exponent is 0 or 1 and the integer result is 150 or normally 285 (284 with downward/toward-zero rounding). A double multiply preserves the active MXCSR rounding mode for level 2. Other cases retain 99999. Implemented without a call or stack frame. This range is not fundamentally impossible for a C compiler to prove; restructuring C can expose it too. |
| Scale the three floats together | Valid with corrections. Implemented using SSE2, preserving the existing minimum CPU requirement and the scalar multiply/add order. A per-type slope table leaves fire rates unchanged for types 2, 8 and 9. The integer fourth lane is masked **before** floating-point multiplication and restored with an integer store. `blendps` requires SSE4.1, and blending afterward does not prevent the preceding multiplication from processing integer 1 as a subnormal float. Type and level also need separate indices; the proposed snippet cannot use `rax` for both. |
| Remove integer division | Valid. A small aether-price table replaces `div`; invalid negative types still return 0 and invalid positive types still return 5049. The proposed unsigned reciprocal multiplication also computes division by 20 with a full 64-bit product and shift by 36. The table is simpler here. Measurements do not establish a speedup for this getter. |
| Precompute finished records | Feasible, but neither a required layout change nor proven fastest. A table for 12 types × 3 levels would occupy 576 bytes for the existing 16-byte records. XP, bounds checks and a fallback for other levels would still be needed: this function accepts arbitrary signed integer levels. C can use static tables too, without requiring C++ `constexpr`. Deferred rather than assuming that a larger table and extra level checks beat the measured SIMD path. |
| Break the internal ABI | Possible, but unnecessary here. Public C/render/test entry points retain System V. C can inline calls, use LTO, or let a compiler choose conventions for private functions; custom internal interfaces are not an exclusive assembly advantage. Keeping the existing interface costs no callee-save overhead in the new leaf implementation. |

## Measurements

The measurements below and their linked raw samples describe the original PR
commit `aafacdf7e59e587dc46c3b71d1a109ee106fee12`, before review fixes.
The current implementation retains the level-2 floating multiply for rounding
parity. The benchmark now builds a fresh temporary C reference with explicit
`-O3 -ffp-contract=off -std=c99` flags so cached Make artifacts cannot affect it.
These earlier timings do not measure the final review fixes.

One executable links the previous NASM catalog, the new NASM catalog and the
unchanged C reference under separate symbols. Both C translation units use GCC
`-O3 -ffp-contract=off -std=c99`, with no LTO. Calls are through function pointers
for all implementations, so this measures the existing function boundary.
Eleven randomized triplets per workload run on one pinned CPU after calibration
and warmup. Each triplet checks the complete final tower-state hash. Confidence
intervals bootstrap paired elapsed-time ratios. The same 5% median slowdown
tolerance as the existing game benchmark applies against both references.

These are catalog microbenchmarks, not whole-game FPS measurements.
`ConfigureTowerStats` runs when building, upgrading and leveling towers, rather
than every frame. Cache behavior, call-site patterns and other machines can
change the results. Passing a finite tolerance does not prove zero regression
on every possible workload.

| Workload | Speedup vs old NASM | Speedup vs C | New/old time, 95% interval | New/C time, 95% interval |
| --- | ---: | ---: | --- | --- |
| configure-level1 | 3.30× | 3.95× | 0.291–0.319 | 0.248–0.261 |
| configure-level2 | 5.36× | 5.31× | 0.163–0.192 | 0.181–0.195 |
| configure-level3 | 1.77× | 1.53× | 0.556–0.589 | 0.641–0.688 |
| configure-specialized | 1.80× | 1.65× | 0.539–0.585 | 0.575–0.651 |
| configure-mixed | 2.29× | 2.36× | 0.420–0.459 | 0.418–0.440 |
| configure-high-level | 1.66× | 1.60× | 0.580–0.636 | 0.587–0.659 |
| aether-cost | 0.98× | 1.03× | 0.978–1.039 | 0.946–1.014 |
| gold-cost | 1.18× | 0.99× | 0.831–0.873 | 0.991–1.044 |

The unchanged gold getter is a control. Differences between its old and new
copies illustrate that code placement and timing noise affect tiny functions;
they are not an optimization claim. The aether getter removes division but has
no established elapsed-time improvement in this run.

## Review-fix validation

[Review-fix samples](catalog-review-benchmark.json) record five randomized
triplets per workload on this workspace with a 20 ms calibration target.
All state hashes matched and all eight scenarios passed the 5% median
regression gate. A deliberately stale `-O0` `build/reference-test.o` remained
byte-identical throughout the run, confirming the benchmark uses its freshly
compiled temporary optimized reference. These short samples validate the
benchmark fix; they do not replace the original eleven-triplet measurements.
The current unit suite passes 108 tests / 34,707 assertions for each implementation,
including level-2 XP under all four MXCSR rounding modes.

## Correctness and reproduction

- 107 named unit tests and 34,691 assertions pass separately for NASM and C.
- New tests compare entire tower objects exactly for all 12 types at 12 signed
  levels, including both integer extremes, and check invalid-type fallbacks.
- The MXCSR regression test disables DAZ/FTZ and verifies that no integer lane
  causes a denormal operand exception. Removing the mask makes this test fail.
- All 15,620 integration state/RNG records, 28 inspector clicks, ten beam cases,
  26 exact PNG comparisons, seven X11 lookup tests and shipping-executable
  input/exit checks pass. C reference and test fixtures pass ASan/UBSan.
- Formatting passes; regeneration preserves all 22 handwritten modules.
  Catalog disassembly has no calls, division or SSE4.1 blend, and `nm -u` is empty.

Run `make check`, `make sanitize`, and `make format-check`. To reproduce the
catalog comparison from the repository root:

```sh
python3 tests/benchmark_catalog.py --baseline 855442b0b225bb8b67d66de306a59693fcb9ef21
```

The script requires NASM, GCC, binutils, the vendored Raylib archive, and Linux
CPU affinity support. Set `NASM` to an alternate assembler path if necessary.
Earlier whole-game measurements remain separately labeled in
[PERFORMANCE.md](PERFORMANCE.md); they have not been rerun or relabeled as
measurements of this catalog change.
