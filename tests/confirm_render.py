#!/usr/bin/env python3
"""Confirm a rendering result using balanced order and an identical-C control.

Uses the same 30-frame render-normal workload as the default benchmark.
Writes every sample and executable hash to results/render-confirmation.json.
"""

import argparse, hashlib, json, os, random, re, statistics, subprocess
from common import ROOT, display

root = ROOT
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument(
    "--workload", choices=("render-title", "render-normal", "render"), default="render-normal"
)
workload = parser.parse_args().workload
cpu = min(os.sched_getaffinity(0))
os.sched_setaffinity(0, {cpu})
rng = random.Random(41083)
report = {
    "workload": workload,
    "rounds": 30,
    "cpu_affinity": cpu,
    "groups": {},
    "binary_sha256": {
        kind: hashlib.sha256((root / f"build/test-{kind}").read_bytes()).hexdigest()
        for kind in ["c", "asm"]
    },
}


def run(kind, env):
    p = subprocess.run(
        [root / f"build/test-{kind}", "bench", workload, "30"],
        env=env,
        check=True,
        stdout=subprocess.PIPE,
        text=True,
        timeout=60,
    )
    m = re.search(r"^RESULT \S+ \d+ ([\d.]+) ([0-9a-f]+)$", p.stdout, re.M)
    assert m, p.stdout
    return float(m[1]), m[2]


with display() as env:
    env["LP_NUM_THREADS"] = "1"
    run("c", env)
    run("asm", env)
    for label, pairs, kinds in [
        ("c_vs_c_control", 16, {"a": "c", "b": "c"}),
        ("nasm_vs_c", 32, {"a": "c", "b": "asm"}),
    ]:
        orders = [["a", "b"], ["b", "a"]] * (pairs // 2)
        rng.shuffle(orders)
        samples = []
        for index, order in enumerate(orders):
            values = {kind: run(kinds[kind], env) for kind in order}
            assert values["a"][1] == values["b"][1]
            samples.append(
                {
                    "order": order,
                    "a_seconds": values["a"][0],
                    "b_seconds": values["b"][0],
                    "state_hash": values["a"][1],
                }
            )
            if (index + 1) % 4 == 0:
                print(label, index + 1, "/", pairs, flush=True)
        ratios = [v["b_seconds"] / v["a_seconds"] for v in samples]
        boots = sorted(statistics.median(rng.choices(ratios, k=pairs)) for _ in range(20000))
        ci = [boots[499], boots[19499]]
        report["groups"][label] = {
            "pairs": pairs,
            "kinds": kinds,
            "samples": samples,
            "b_over_a_ratio": statistics.median(ratios),
            "ratio_bootstrap_95_ci": ci,
        }
        (root / "results/render-confirmation.json").write_text(json.dumps(report, indent=2) + "\n")
        print(label, statistics.median(ratios), ci, flush=True)
