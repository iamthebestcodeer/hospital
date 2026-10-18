#!/usr/bin/env python3
"""Compare the old NASM catalog, current NASM and optimized C in one executable."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import random
import statistics
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SYMBOLS = (
    "GetTowerCost",
    "GetTowerAetherCost",
    "GetAimToleranceDegrees",
    "ConfigureTowerStats",
)
MODES = (
    "configure-level1",
    "configure-level2",
    "configure-level3",
    "configure-specialized",
    "configure-mixed",
    "configure-high-level",
    "aether-cost",
    "gold-cost",
)
REGRESSION_LIMIT = 1.05


def run(binary, kind, mode, rounds):
    result = subprocess.check_output([binary, kind, mode, str(rounds)], text=True).split()
    assert result[0] == "RESULT", result
    return float(result[1]), result[2]


def interval(values, rng):
    samples = sorted(statistics.median(rng.choices(values, k=len(values))) for _ in range(10000))
    return [samples[249], samples[9749]]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", required=True, help="Git commit containing the old catalog")
    parser.add_argument("--pairs", type=int, default=11)
    parser.add_argument("--seconds", type=float, default=0.075)
    args = parser.parse_args()
    if args.pairs < 5 or args.seconds <= 0:
        parser.error("Use at least five pairs and positive sample duration")
    baseline = subprocess.check_output(
        ["git", "rev-parse", "--verify", args.baseline + "^{commit}"],
        cwd=ROOT,
        text=True,
    ).strip()
    old = subprocess.check_output(
        ["git", "show", baseline + ":src/domain/tower_catalog.asm"], cwd=ROOT
    )
    cpu = min(os.sched_getaffinity(0))
    os.sched_setaffinity(0, {cpu})
    nasm = os.environ.get("NASM", "nasm")
    rng = random.Random(12573)
    report = {
        "baseline_commit": baseline,
        "cpu_affinity": cpu,
        "platform": platform.platform(),
        "cpu": next(
            line.split(":", 1)[1].strip()
            for line in Path("/proc/cpuinfo").read_text().splitlines()
            if line.startswith("model name")
        ),
        "nasm": subprocess.check_output([nasm, "-v"], text=True).strip(),
        "compiler": subprocess.check_output(["gcc", "--version"], text=True).splitlines()[0],
        "c_flags": "-O3 -ffp-contract=off -std=c99; separate translation units; no LTO",
        "target_seconds_per_baseline_sample": args.seconds,
        "median_regression_limit": REGRESSION_LIMIT,
        "reference_source_sha256": hashlib.sha256(
            (ROOT / "reference/linux.c").read_bytes()
        ).hexdigest(),
        "driver_sha256": hashlib.sha256(
            (ROOT / "tests/performance/catalog.c").read_bytes()
        ).hexdigest(),
        "catalog_sha256": {
            "before": hashlib.sha256(old).hexdigest(),
            "after": hashlib.sha256(
                (ROOT / "src/domain/tower_catalog.asm").read_bytes()
            ).hexdigest(),
        },
        "measurements": [],
    }
    with tempfile.TemporaryDirectory() as directory:
        temporary = Path(directory)
        reference = temporary / "reference-test.o"
        subprocess.run(
            [
                "gcc",
                "-O3",
                "-ffp-contract=off",
                "-std=c99",
                "-Iinclude",
                "-Ivendor/raylib-5.5_linux_amd64/include",
                "-Dmain=VanguardMain",
                "-c",
                "reference/linux.c",
                "-o",
                str(reference),
            ],
            cwd=ROOT,
            check=True,
        )
        source = temporary / "before.asm"
        source.write_bytes(old)
        objects = []
        for kind, path in (
            ("before", source),
            ("after", ROOT / "src/domain/tower_catalog.asm"),
        ):
            obj = temporary / (kind + ".o")
            subprocess.run(
                [nasm, "-f", "elf64", "-Werror", str(path), "-o", str(obj)],
                cwd=ROOT,
                check=True,
            )
            subprocess.run(
                [
                    "objcopy",
                    *["--redefine-sym=" + symbol + "=" + kind + "_" + symbol for symbol in SYMBOLS],
                    str(obj),
                ],
                check=True,
            )
            objects.append(str(obj))
        binary = temporary / "catalog-benchmark"
        subprocess.run(
            [
                "gcc",
                "-O3",
                "-ffp-contract=off",
                "-std=c99",
                "-Wall",
                "-Wextra",
                "-Werror",
                "-Iinclude",
                "-Ivendor/raylib-5.5_linux_amd64/include",
                "tests/performance/catalog.c",
                *objects,
                str(reference),
                "vendor/raylib-5.5_linux_amd64/lib/libraylib.a",
                "-lm",
                "-ldl",
                "-lpthread",
                "-o",
                str(binary),
            ],
            cwd=ROOT,
            check=True,
        )
        report["benchmark_binary_sha256"] = hashlib.sha256(binary.read_bytes()).hexdigest()
        for mode in MODES:
            seconds, _ = run(binary, "before", mode, 100000)
            rounds = max(100000, int(100000 * args.seconds / max(seconds, 1e-9)))
            for kind in ("before", "after", "c"):
                run(binary, kind, mode, rounds)
            pairs = []
            for _ in range(args.pairs):
                order = ["before", "after", "c"]
                rng.shuffle(order)
                values = {kind: run(binary, kind, mode, rounds) for kind in order}
                assert len({value[1] for value in values.values()}) == 1, (mode, values)
                pairs.append(
                    {
                        "order": order,
                        "seconds": {k: v[0] for k, v in values.items()},
                        "state_hash": values["after"][1],
                    }
                )
            entry = {"mode": mode, "rounds": rounds, "pairs": pairs}
            for other in ("before", "c"):
                ratios = [p["seconds"]["after"] / p["seconds"][other] for p in pairs]
                entry["after_over_" + other] = {
                    "median": statistics.median(ratios),
                    "bootstrap_95_ci": interval(ratios, rng),
                    "regression": statistics.median(ratios) > REGRESSION_LIMIT,
                }
            report["measurements"].append(entry)
            output = ROOT / "results/catalog-benchmark.json"
            output.parent.mkdir(exist_ok=True)
            output.write_text(json.dumps(report, indent=2) + "\n")
            print(
                f"{mode}: {1/entry['after_over_before']['median']:.2f}x vs old NASM; "
                f"{1/entry['after_over_c']['median']:.2f}x vs C",
                flush=True,
            )
    failures = [
        f"{entry['mode']} vs {other}"
        for entry in report["measurements"]
        for other in ("before", "c")
        if entry["after_over_" + other]["regression"]
    ]
    if failures:
        raise SystemExit("Regression gate FAILED: " + ", ".join(failures))
    print(
        "PASS: all state hashes match; no catalog scenario exceeds the 5% median regression gate."
    )


if __name__ == "__main__":
    main()
