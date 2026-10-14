.DEFAULT_GOAL := all
CC = gcc
NASM = nasm
PYTHON = python3
BLACK = black
CLANG_FORMAT = clang-format
RAYLIB := vendor/raylib-5.5_linux_amd64
CPPFLAGS := -Iinclude -Itests/unit -I$(RAYLIB)/include
CFLAGS := -O3 -ffp-contract=off -std=c99 -Wall -Wextra -Werror -MMD -MP
NASMFLAGS := -f elf64 -Werror
RAYLIB_ARCHIVE := $(RAYLIB)/lib/libraylib.a
LDLIBS := $(RAYLIB_ARCHIVE) -lm -ldl -lpthread
WRAPS := -Wl,--wrap=IsKeyDown,--wrap=IsKeyPressed,--wrap=IsMouseButtonPressed,--wrap=GetMousePosition,--wrap=GetFPS
UNIT_WRAPS := $(WRAPS) -Wl,--wrap=GetAimToleranceDegrees
ASM_SOURCES := $(sort $(foreach directory,application domain gameplay platform generated,$(wildcard src/$(directory)/*.asm)))
ASM_OBJECTS := $(patsubst src/%.asm,build/%.o,$(ASM_SOURCES))
GAME_OBJECTS := $(filter-out build/platform/main.o,$(ASM_OBJECTS))
UNIT_GAME_OBJECTS := $(filter-out build/generated/render.o,$(GAME_OBJECTS))
UNIT_SOURCES := $(filter-out tests/unit/support.c,$(wildcard tests/unit/*.c))
UNIT_OBJECTS := $(patsubst tests/unit/%.c,build/unit/%.o,$(UNIT_SOURCES))
UNIT_OBJECTS += build/unit/register_probe.o

.PHONY: all clean regenerate test test-unit test-tools test-integration smoke check benchmark confirm-render sanitize format format-check
all: build/aetherium

build/%.o: src/%.asm
	@mkdir -p $(dir $@)
	$(NASM) $(NASMFLAGS) -MD $(@:.o=.d) -MT $@ $< -o $@

build/unit/%.o: tests/unit/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

build/unit/register_probe.o: tests/unit/register_probe.asm
	@mkdir -p $(dir $@)
	$(NASM) $(NASMFLAGS) $< -o $@

build/unit/support-reference.o: tests/unit/support.c
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -DTEST_REFERENCE -c $< -o $@

build/aetherium: $(ASM_OBJECTS)
	$(CC) $(filter-out $(RAYLIB_ARCHIVE),$^) $(LDLIBS) -o $@

build/reference.o: reference/linux.c include/aetherium.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

build/rpg-c: build/reference.o
	$(CC) $(filter-out $(RAYLIB_ARCHIVE),$^) $(LDLIBS) -o $@

build/reference-test.o: build/reference.o
	objcopy --redefine-sym main=VanguardMain $< $@

build/harness.o: tests/integration/harness.c include/aetherium.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

build/test-c: build/harness.o build/reference-test.o
	$(CC) $(filter-out $(RAYLIB_ARCHIVE),$^) $(WRAPS) $(LDLIBS) -o $@

build/test-asm: build/harness.o $(GAME_OBJECTS)
	$(CC) $(filter-out $(RAYLIB_ARCHIVE),$^) $(WRAPS) $(LDLIBS) -o $@

build/unit-asm: $(UNIT_OBJECTS) build/unit/support.o $(UNIT_GAME_OBJECTS)
	$(CC) $(filter-out $(RAYLIB_ARCHIVE),$^) $(UNIT_WRAPS) $(LDLIBS) -o $@

build/unit-c: $(UNIT_OBJECTS) build/unit/support-reference.o build/reference-test.o
	$(CC) $(filter-out $(RAYLIB_ARCHIVE),$^) $(UNIT_WRAPS) $(LDLIBS) -o $@

build/reference-sanitized.o: reference/linux.c include/aetherium.h
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer -Dmain=VanguardMain -c $< -o $@

build/unit-sanitized: $(UNIT_SOURCES) tests/unit/support.c tests/unit/test.h build/reference-sanitized.o build/unit/register_probe.o
	$(CC) $(CPPFLAGS) -O1 -g -Wall -Wextra -Werror -fsanitize=address,undefined -fno-omit-frame-pointer -DTEST_REFERENCE $(UNIT_SOURCES) tests/unit/support.c build/reference-sanitized.o build/unit/register_probe.o $(UNIT_WRAPS) $(LDLIBS) -o $@

build/integration-sanitized: tests/integration/harness.c include/aetherium.h build/reference-sanitized.o
	$(CC) $(CPPFLAGS) -O1 -g -Wall -Wextra -Werror -fsanitize=address,undefined -fno-omit-frame-pointer $< build/reference-sanitized.o $(WRAPS) $(LDLIBS) -o $@

# A replaced static archive must relink every consumer, including sanitizer builds.
build/aetherium build/rpg-c build/test-c build/test-asm build/unit-asm build/unit-c build/unit-sanitized build/integration-sanitized: $(RAYLIB_ARCHIVE)

regenerate:
	$(PYTHON) tools/generate.py

test-unit: build/unit-asm build/unit-c
	./build/unit-asm
	./build/unit-c

test-tools:
	NASM="$(NASM)" $(PYTHON) -m unittest discover -s tests/tooling -v

test-integration: build/test-c build/test-asm
	$(PYTHON) tests/verify.py

test: test-tools test-unit test-integration

smoke: build/aetherium
	$(PYTHON) tests/window_lookup.py
	$(PYTHON) tests/smoke.py

check: test smoke

benchmark: build/test-c build/test-asm
	$(PYTHON) tests/benchmark.py

confirm-render: build/test-c build/test-asm
	$(PYTHON) tests/confirm_render.py

sanitize: build/unit-sanitized build/integration-sanitized
	@mkdir -p results
	ASAN_OPTIONS=detect_leaks=1 ./build/unit-sanitized
	ASAN_OPTIONS=detect_leaks=1 ./build/integration-sanitized verify > results/sanitizer-state.txt 2> results/sanitizer.log

format:
	$(CLANG_FORMAT) -i tests/unit/*.c tests/unit/test.h tests/integration/harness.c
	$(BLACK) tools tests

format-check:
	$(CLANG_FORMAT) --dry-run --Werror tests/unit/*.c tests/unit/test.h tests/integration/harness.c
	$(BLACK) --check tools tests

clean:
	rm -rf build

-include $(wildcard build/*.d build/*/*.d)
