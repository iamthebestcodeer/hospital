#!/usr/bin/env python3
"""Paired randomized benchmark against the original game compiled with -O3.
Each result includes exact final state equality. Fail on a >5% slowdown in
median elapsed time; retain uncertainty bounds instead of asserting universal
performance from a finite sample. The threshold is declared before measuring.
"""

import json, math, os, platform, random, re, statistics, subprocess
from common import ROOT, display

MODES = [
    "spawn-zero",
    "spawn-one",
    "spawn-small",
    "spawn-empty",
    "spawn-dense",
    "spawn-full",
    "idle",
    "normal",
    "stress",
    "vfx",
    "render-title",
    "render-normal",
    "render",
]
PAIRS = int(os.environ.get("BENCH_PAIRS", "11"))
TARGET_SECONDS = float(os.environ.get("BENCH_SECONDS", "0.15"))
REGRESSION_LIMIT = 1.05
rng = random.Random(20261014)
cpu = min(os.sched_getaffinity(0))
os.sched_setaffinity(0, {cpu})


def run(kind, mode, rounds, env):
    p = subprocess.run(
        [ROOT / f"build/test-{kind}", "bench", mode, str(rounds)],
        env=env,
        check=True,
        stdout=subprocess.PIPE,
        text=True,
        timeout=120,
    )
    m = re.search(r"^RESULT (\S+) (\d+) ([\d.]+) ([0-9a-f]+)$", p.stdout, re.M)
    if not m:
        raise RuntimeError(p.stdout)
    return float(m[3]), m[4]


def interval(ratios):
    medians = [statistics.median(rng.choices(ratios, k=len(ratios))) for _ in range(10000)]
    medians.sort()
    return [medians[249], medians[9749]]


with display() as env:
    env["LP_NUM_THREADS"] = "1"
    measurements = []
    for mode in MODES:
        # Calibration and warmup discarded. Use the same rounds for both builds.
        pilot_rounds = 30 if mode.startswith("render") else 1000
        seconds, _ = run("c", mode, pilot_rounds, env)
        rounds = max(
            30 if mode.startswith("render") else 1000,
            min(5000000, int(pilot_rounds * TARGET_SECONDS / max(seconds, 1e-9))),
        )
        run("asm", mode, rounds, env)
        samples = []
        for pair in range(PAIRS):
            order = ["c", "asm"]
            rng.shuffle(order)
            values = {}
            for kind in order:
                values[kind] = run(kind, mode, rounds, env)
            assert values["c"][1] == values["asm"][1], f"{mode}: state mismatch"
            samples.append(
                {
                    "order": order,
                    "c_seconds": values["c"][0],
                    "asm_seconds": values["asm"][0],
                    "state_hash": values["c"][1],
                }
            )
        ratios = [v["asm_seconds"] / v["c_seconds"] for v in samples]
        median_ratio = statistics.median(ratios)
        ci = interval(ratios)
        entry = {
            "mode": mode,
            "rounds": rounds,
            "pairs": PAIRS,
            "samples": samples,
            "median_c_seconds": statistics.median(v["c_seconds"] for v in samples),
            "median_asm_seconds": statistics.median(v["asm_seconds"] for v in samples),
            "speedup": 1 / median_ratio,
            "asm_over_c_ratio": median_ratio,
            "ratio_bootstrap_95_ci": ci,
            "regression": median_ratio > REGRESSION_LIMIT,
        }
        measurements.append(entry)
        print(
            f"{mode:14} speedup {entry['speedup']:7.2f}x; ASM/C {median_ratio:.3f} "
            f"(95% paired CI {ci[0]:.3f}–{ci[1]:.3f})",
            flush=True,
        )
        # Save each completed scenario so interrupted runs retain their evidence.
        report = {
            "platform": platform.platform(),
            "machine": platform.machine(),
            "cpu_affinity": cpu,
            "cpu": next(
                (
                    l.split(":", 1)[1].strip()
                    for l in open("/proc/cpuinfo")
                    if l.startswith("model name")
                ),
                "unknown",
            ),
            "compiler": subprocess.check_output(["gcc", "--version"], text=True).splitlines()[0],
            "c_flags": "-O3 -ffp-contract=off -std=c99",
            "raylib": "5.5 (same static library)",
            "render_backend": "Xvfb, Mesa software OpenGL, LP_NUM_THREADS=1",
            "target_seconds_per_sample": TARGET_SECONDS,
            "median_regression_limit": REGRESSION_LIMIT,
            "measurements": measurements,
        }
        (ROOT / "results/benchmark.json").write_text(json.dumps(report, indent=2) + "\n")
failures = [e["mode"] for e in measurements if e["regression"]]
if failures:
    raise SystemExit("Regression gate FAILED: " + ", ".join(failures))
print("PASS: all final state hashes match; no scenario exceeds the declared 5% regression gate.")
