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
