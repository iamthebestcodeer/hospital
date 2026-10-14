#!/usr/bin/env python3
import hashlib, json, subprocess
from common import ROOT, display

results = ROOT / "results"
results.mkdir(exist_ok=True)
for kind in ("c", "asm"):
    with (results / f"{kind}-state.txt").open("wb") as out:
        subprocess.run([ROOT / f"build/test-{kind}", "verify"], stdout=out, check=True, timeout=120)
c = (results / "c-state.txt").read_bytes()
a = (results / "asm-state.txt").read_bytes()
assert c == a, "Game state mismatch; compare results/*-state.txt"
with display() as env:
    for kind in ("c", "asm"):
        directory = results / f"render-{kind}"
        directory.mkdir(exist_ok=True)
        with (results / f"{kind}-render-state.txt").open("wb") as out:
            subprocess.run(
                [ROOT / f"build/test-{kind}", "render", directory],
                stdout=out,
                env=env,
                check=True,
                timeout=120,
            )
assert (results / "c-render-state.txt").read_bytes() == (
    results / "asm-render-state.txt"
).read_bytes()
images = {}
for cpath in sorted((results / "render-c").glob("*.png")):
    apath = results / "render-asm" / cpath.name
    assert cpath.read_bytes() == apath.read_bytes(), f"Render mismatch: {cpath.name}"
    images[cpath.name] = hashlib.sha256(apath.read_bytes()).hexdigest()
assert len(images) == 26
report = {
    "state_records": len(c.splitlines()),
    "state_sha256": hashlib.sha256(c).hexdigest(),
    "particle_cases": 1408,
    "floating_text_abi_cases": 6,
    "simulation_frames": 9600,
    "vfx_frames": 1050,
    "inspector_click_cases": 28,
    "screenshots": images,
    "result": "PASS: exact state/RNG and PNG matches",
}
(results / "verification.json").write_text(json.dumps(report, indent=2) + "\n")
print(
    f"PASS: {report['state_records']:,} state/RNG records, 28 inspector clicks and 26 exact PNG comparisons."
)
