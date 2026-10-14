# Differential validation

Both test executables link the same harness and the same Raylib 5.5 static
library. `test-c` links the corrected Linux C reference compiled with `-O3`; `test-asm` links the
NASM game. Only input and FPS queries are wrapped. Assertions check key
rules independently; exact state/RNG hashes detect changes in all stored fields.
Pointer addresses and OpenGL object names are removed from state hashes; tooltip
string contents are included. PNG comparisons check rendering separately.

| Area | Checks |
| --- | --- |
| Particle spawning | 1,408 cases: eight seeds × eight pool layouts × eleven counts × gravity on/off; negative/zero counts, one slot, 250-particle bursts, 3,000/3,001 requests, full/fragmented pools, lowest-slot order, next RNG result; 1,000 reuse frames |
| VFX integration | 1,050 frames covering sparse/dense/empty pools, both gravity modes, expiration, text deceleration, and seven dt values from -0.05 through 0.25 seconds |
| Floating text/ABI | Plain text padding/truncation, integer varargs overflowing GP registers, floating varargs overflowing XMM registers, critical values, oldest-slot replacement, and no RNG consumption when no text slot qualifies |
| Towers/resources | All base towers and eight upgrade paths; path/out-of-bounds/occupied rejection; build costs; XP to level 3; invalid upgrade; sale refund and occupancy clearing |
| Enemies/combat | Signed-boundary tower aiming still fires; All eight enemy types; all twelve tower weapons and four target modes over 960 frames; projectile impacts, AoE/chain, enemy abilities, spawner death/minions |
| Status/damage | Six status types, weaker-effect rejection, physical/energy/true damage, status processing and boss resistances |
| Hero/state | Restart clears shake timer, intensity, duration and camera offset; Four hero skills; XP; movement, attack, dash, burst; pause/resume, game over, restart; skill overlay stays open with points remaining and resumes play after the last point is spent |
| Waves | Wave tiers 1–20, enemy compositions, boss/spawner introductions, completion bonuses |
| Integrated simulation | Four seeded, 2,400-frame scenes with 100 towers, 300 enemies and 2,500 initial particles; varied dt, scripted abilities/movement, pause/grid and skill allocation |
| Rendering/UI | Ten Cryo/Freezer beam midpoint checks across signed-angle boundaries, including misaligned negative controls; 28 asserted inspector clicks across all four base types: both upgrades, the gap, and the sell region; 26 PNGs: title, pause, game over, four skill selections, twelve tower inspectors, four build previews/grid, specialization click, sell click and start transition; tooltips, lighting, map, entities and effects |

`tools/sanitizers.sh` checks the C reference/harness with AddressSanitizer and
UndefinedBehaviorSanitizer on the headless verification cases. Its log is
written to `results/sanitizer.log`.
Assembly instructions cannot be instrumented by these sanitizers; their memory
behavior is checked through exact state comparisons and boundary cases instead.

These are finite automated tests. They do not constitute exhaustive proof for
all input sequences, floating-point edge cases, graphics drivers or hardware.
