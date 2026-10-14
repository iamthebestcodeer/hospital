#!/usr/bin/env python3
"""Generate only rendering/UI assembly and ABI offsets; gameplay is handwritten."""

from pathlib import Path
import subprocess
import re
from gas_to_nasm import convert
from reference_fixes import correct_reference

RENDER_EXPORTS = {
    "AVDrawRectangleRoundedLinesEx",
    "BuildStaticMapRT",
    "DrawBuildMenu",
    "DrawEnemies",
    "DrawEntities",
    "DrawGame",
    "DrawHero",
    "DrawHeroStatus",
    "DrawMap",
    "DrawProjectiles",
    "DrawTooltip",
    "DrawTowerInspector",
    "DrawTowerUpgradePaths",
    "DrawTowers",
    "DrawUI",
    "DrawVFX",
    "GetTowerColor",
    "GetTowerDescription",
    "GetTowerName",
    "GuiButton",
    "SetTooltip",
}


def remove_definition(text, name):
    pattern = r"^([A-Za-z_][\w *]+\b" + re.escape(name) + r"\([^;{}]*\))\s*\{"
    match = re.search(pattern, text, re.M)
    if not match:
        raise ValueError("No reference definition for handwritten function " + name)
    depth = 1
    tokens = r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\x27(?:\\.|[^\x27\\])*\x27|[{}]'
    for token in re.finditer(tokens, text[match.end() :]):
        if token[0] == "{":
            depth += 1
        if token[0] == "}":
            depth -= 1
        if depth == 0:
            end = match.end() + token.end()
            return text[: match.start()] + match[1] + ";" + text[end:]
    raise ValueError("Unbalanced reference definition: " + name)


def validate_render_exports(assembly):
    generated = set(re.findall(r"^\s*\.globl\s+(\w+)", assembly, re.M))
    unexpected = generated - RENDER_EXPORTS
    if unexpected:
        raise ValueError(
            "Refusing to generate gameplay instructions: " + ", ".join(sorted(unexpected))
        )


def main():
    root = Path(__file__).resolve().parents[1]
    (root / "build").mkdir(exist_ok=True)
    source = (root / "reference/rpg.c").read_text()
    source = correct_reference(source)
    # Raylib 5.5 exports the fallback's name. Preserve its implementation under a unique name.
    source = source.replace("DrawRectangleRoundedLinesEx(", "AVDrawRectangleRoundedLinesEx(")
    source = source.replace("static GameData game = {0};", "GameData game = {0};")
    (root / "reference/linux.c").write_text(source)
    header = source[: source.index("int main(void) {")].replace(
        "GameData game = {0};", "extern GameData game;"
    )
    (root / "include/aetherium.h").write_text(
        "/* Generated ABI contract; regenerate with make regenerate. */\n#ifndef AETHERIUM_H\n#define AETHERIUM_H\n"
        + header.replace("static inline Enemy* GetEnemyFromPair(int index, int id);", "")
        + "\n#endif\n"
    )

    handwritten = []
    for path in sorted((root / "src").rglob("*.asm")):
        if "generated" not in path.parts:
            handwritten += re.findall(r"^global (\w+)$", path.read_text(), re.M)
    translated = source.replace("GameData game = {0};", "extern GameData game;")
    for name in handwritten:
        if name != "game" and not name.startswith("av_"):
            translated = remove_definition(translated, name)
    (root / "build/translate.c").write_text(translated)
    subprocess.run(
        [
            "gcc",
            "-O3",
            "-ffp-contract=off",
            "-std=c99",
            "-masm=intel",
            "-fno-asynchronous-unwind-tables",
            "-I" + str(root / "vendor/raylib-5.5_linux_amd64/include"),
            "-S",
            str(root / "build/translate.c"),
            "-o",
            str(root / "build/game.S"),
        ],
        check=True,
    )
    asm = (
        (root / "build/game.S").read_text().replace(str(root / "build/translate.c"), "translate.c")
    )
    validate_render_exports(asm)
    (root / "src/generated/render.asm").write_text(
        "; Rendering/UI translated from corrected reference/linux.c.\n; Gameplay is handwritten in src/domain, src/gameplay, src/application and src/platform.\n"
        + convert(asm)
    )
    # Ask the compiler for the ABI layout instead of guessing struct padding.
    fields = {
        "GAME_PARTICLES": "offsetof(GameData, particles)",
        "PARTICLE_SIZE": "sizeof(Particle)",
        "P_POSITION": "offsetof(Particle, position)",
        "P_VELOCITY": "offsetof(Particle, velocity)",
        "P_START_COLOR": "offsetof(Particle, startColor)",
        "P_END_COLOR": "offsetof(Particle, endColor)",
        "P_LIFE": "offsetof(Particle, life)",
        "P_MAX_LIFE": "offsetof(Particle, maxLife)",
        "P_START_SIZE": "offsetof(Particle, startSize)",
        "P_END_SIZE": "offsetof(Particle, endSize)",
        "GAME_TEXTS": "offsetof(GameData, floatingTexts)",
        "TEXT_SIZE": "sizeof(FloatingText)",
        "FT_Y": "offsetof(FloatingText, position.y)",
        "FT_LIFE": "offsetof(FloatingText, lifetime)",
        "FT_VY": "offsetof(FloatingText, velocityY)",
        "FT_ACTIVE": "offsetof(FloatingText, active)",
        "P_ACTIVE": "offsetof(Particle, active)",
        "P_GRAVITY": "offsetof(Particle, gravity)",
    }
    probe = '#include <stddef.h>\n#include "aetherium.h"\nint main(void){\n'
    for k, v in fields.items():
        probe += 'printf(".equ ' + k + ', %zu\\n", (size_t)(' + v + "));\n"
    probe += 'printf(".equ PARTICLE_COUNT, %d\\n", MAX_PARTICLES);\n}\n'
    (root / "build/layout.c").write_text(probe)
    subprocess.run(
        [
            "gcc",
            "-I" + str(root / "include"),
            "-I" + str(root / "vendor/raylib-5.5_linux_amd64/include"),
            str(root / "build/layout.c"),
            "-o",
            str(root / "build/layout"),
        ],
        check=True,
    )
    (root / "src/include/layout.inc").write_text(
        convert(subprocess.check_output([str(root / "build/layout")]).decode())
    )

    # Named offsets let the handwritten NASM express the ABI without magic numbers.
    structures = {
        "G": (
            "GameData",
            "state map hero camera towers enemies projectiles particles floatingTexts lives gold aether currentWave waveTimer enemiesToSpawn spawnTimer waveActive placingTower selectedTowerIndex showGrid enemyIdCounter globalTime tooltip screenShakeIntensity screenShakeTime screenShakeDuration dayNightCycle environmentColor mapRT mapRTBuilt occupied",
        ),
        "H": (
            "Hero",
            "position level xp xpToNextLevel skillPoints speed attackDamage attackRange attackCooldown currentCooldown dashCooldown currentDashCooldown dashTimer dashDirection lastMovementDirection burstCooldown currentBurstCooldown burstDamage burstRange skills",
        ),
        "T": (
            "Tower",
            "position type stats damageType cooldownTimer targetIndex targetEnemyId rotation desiredRotation visualRecoil active targetingMode kills totalCost",
        ),
        "E": (
            "Enemy",
            "position type id hp maxHp speed baseSpeed armor energyResist goldValue aetherValue xpValue waypointIndex active abilityTimer status statusCount",
        ),
        "J": (
            "Projectile",
            "position speed damage damageType aoeRadius sourceType sourceTowerIndex targetIndex targetEnemyId targetPosition active chainCount hitHistory hitCount applyStatus statusDuration statusIntensity",
        ),
        "S": ("TowerStats", "level xp xpToNextLevel damage range fireRate"),
        "M": ("GameMap", "tiles waypoints waypointCount"),
        "F": ("FloatingText", "position text color lifetime velocityY active critical"),
    }
    probe = '#include <stddef.h>\n#include "aetherium.h"\nint main(void){\n'
    for prefix, (ctype, names) in structures.items():
        probe += f'printf("{prefix}_SIZE equ %zu\\n", sizeof({ctype}));\n'
        for name in names.split():
            probe += f'printf("{prefix}_{name} equ %zu\\n", offsetof({ctype}, {name}));\n'
    probe += "}\n"
    (root / "build/abi.c").write_text(probe)
    subprocess.run(
        [
            "gcc",
            "-I" + str(root / "include"),
            "-I" + str(root / "vendor/raylib-5.5_linux_amd64/include"),
            str(root / "build/abi.c"),
            "-o",
            str(root / "build/abi"),
        ],
        check=True,
    )
    (root / "src/include/abi.inc").write_bytes(subprocess.check_output([str(root / "build/abi")]))


if __name__ == "__main__":
    main()
