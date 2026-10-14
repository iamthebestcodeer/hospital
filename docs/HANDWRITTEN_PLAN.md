# Handwritten NASM scope

The agreed first stage is handwritten gameplay/performance code, with rendering
and UI written by hand as a longer term goal.

Gameplay is now organized into `src/domain/`, `src/gameplay/`,
`src/application/`, and `src/platform/` modules. It includes all simulation entry
points, the main loop, input, initialization, resources, progression,
entity construction, damage/status effects, targeting, collision, and floating
text formatting. Particle allocation and VFX integration remain handwritten.

`src/generated/render.asm` contains the remaining generated drawing routines,
static map render-target builder, GUI/tooltip helpers and display lookups.
`make regenerate` discovers handwritten exports and excludes their C definitions.
It never generates handwritten modules. See [architecture](ARCHITECTURE.md).

## Rendering rewrite stages

1. Static map and basic entity drawing.
2. Effects, hero/enemy/tower/projectile drawing and lighting.
3. Menus, inspectors, skill selection, tooltips and state overlays.
4. Remaining display helpers, then removal of the rendering translator.

Each stage must retain unit/ABI checks, exact state/RNG comparisons, all 26 PNG
comparisons, real X11 input tests, and paired performance measurements. Preserve
draw order, effects, MSAA and entity limits; report graphics uncertainty separately
from simulation speedups.
