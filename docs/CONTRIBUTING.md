# Contributing

1. Find the owning module in the README. Add a failing named test for the rule
   or bug in the corresponding `tests/unit/*_test.c` suite.
2. Run `make test-unit`. Both NASM and C must pass for behavior-preserving work.
   An intentional change from the original game needs a separately reviewed
   reference expectation; do not weaken the comparison just to get green tests.
3. Change the smallest relevant module. Keep dependencies explicit and preserve
   the ABI. Do not add graphics, input, or RNG calls to `src/domain`.
4. Run `make format`, `make check`, and `make sanitize`. Use `make benchmark`
   for gameplay/hot-loop changes or changes to object layout. Keep raw results.

## Conventions

Use behavior-oriented test names and an arrange/act/assert structure. Reset state
between tests; use deterministic seeds. Table-driven tests and properties should
express independent invariants, not duplicate the implementation line for line.
Prefer a few boundary cases with clear failure messages over snapshots alone.

Keep assembly local labels scoped to their function. Document pointer/register
arguments for internal interfaces. Preserve RBX/RBP/R12–R15 and stack alignment;
assume every XMM register may change across an external call. Use shared macros
for calling conventions rather than copying prologues.

Small constants may be private to a module. Keep shared mechanisms in
`src/include/calling_convention.inc`; gameplay policy belongs to its owning
module. Add wrappers/frameworks only when they remove actual duplication or make
a dependency testable. Keep the C original unchanged in `reference/rpg.c`.

## Generated files

Edit handwritten modules directly. Run `make regenerate` after ABI changes or
rendering-reference maintenance. It writes generated rendering, layout includes,
the public test contract and Linux reference adapter. Review those outputs;
never hand-edit generated instructions to hide a gameplay change. Checked-in
rendering was produced with GCC 14.2, so different GCC versions may change it.

## Useful commands

```sh
make -j2
make test-unit test-tools
make check
make sanitize
make format-check
make benchmark
```

`make clean` removes only build products. Headers and assembly includes have
automatic dependencies. After moving source files, a clean build removes stale
dependency files from their old locations.
