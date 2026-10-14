# Review corrections

The supplied `reference/rpg.c` stays unchanged for provenance. The following
inherited bugs are corrected in handwritten gameplay and the Linux reference.
`tools/reference_fixes.py` applies the C/UI corrections during regeneration;
guarded replacements and tooling tests prevent silently losing them.

- **Inspector controls:** specialization buttons now occupy y=630–680 and
  y=695–745. The sell button remains at y=750–790. An upgrade click cannot
  also sell the tower. The real renderer is exercised with 28 clicks across
  all four base tower types, checking activity, type, resource balances,
  accumulated cost and selection.
- **Spawner deaths:** position and XP are captured before freeing the enemy
  slot. All four minions use offsets from the original spawner position, and
  rewards use its 250 XP even when a minion immediately reuses that slot.
  Tests check tower XP, kill count, hero direct/global XP, gold, aether and
  identical seeded minion positions with and without reuse of the dead slot.
- **Chain lightning:** a chain impact snapshots its projectile data before
  allocating the successor. The current target receives full damage and the
  successor carries 70%, independent of free-slot order. The current slot
  remains available even when the pool is otherwise full. Tests exercise
  current-slot reuse, a lower free slot and a saturated pool, then verify the
  successor's actual hit, target and history. Critical hits still double damage.

Each new behavioral regression was confirmed to reject the old implementation.
These corrections intentionally change some state hashes and inspector images;
differential tests require NASM and corrected C to agree exactly. Earlier
measurements are archived in `results/history/pre-review`; current performance
measurements compare the corrected implementations.

## PR #2 review

All six findings from Codex and Greptile were valid:

- Normalize a negative `fmodf` result before comparing tower aim tolerance.
  Targets across the signed angle boundary remain fireable in either direction.
- Reset the entire screen-shake effect and camera offset during restart.
  A fresh game has no leftover timer, intensity, or division by zero duration.
- Track the Raylib archive as a dependency of every executable, including
  sanitizer targets. An isolated make test proves an updated archive schedules
  exactly one relink with exactly one archive argument for each consumer.
- Call game entry points directly from the assembly register probe, supplying
  their integer and floating-point arguments. Check full 64-bit sentinels before
  any C code runs; six broken callees test each register check independently.
- Observe the shipping executable's pixels after real Enter and D events.
  The hero must appear at spawn, then move right by over 20 pixels. Mutants
  ignoring either action fail, even though Escape still exits successfully.
- Pin checkout to the verified `actions/checkout` v4.3.1 commit
  `34e114876b0b11c390a56381ad16ebd13914f8d5` for reproducible workflow code.

The angle and reset corrections are also applied to the Linux C reference by
`tools/reference_fixes.py`. The original supplied C file is still unchanged.
