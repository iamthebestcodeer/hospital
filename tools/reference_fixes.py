"""Explicit corrections to the preserved upstream game, shared by reference and UI generation."""


def replace_once(source, before, after):
    if source.count(before) != 1:
        raise ValueError("Reference correction no longer matches exactly once: " + before)
    return source.replace(before, after, 1)


def correct_reference(source):
    # Both specialization buttons must end above the sell control at y=750.
    source = replace_once(
        source,
        "    int startY = 630;\n    int buttonHeight = 70;",
        "    int startY = 630;\n    int buttonHeight = 50;",
    )
    # A dead spawner's storage may be reused by the very first minion.
    source = replace_once(
        source,
        "    e->active = false;\n\n    // Rewards",
        "    const Vector2 deathPosition = e->position;\n"
        "    const int deathXP = e->xpValue;\n"
        "    e->active = false;\n\n    // Rewards",
    )
    for before, after in (
        ("Vector2Add(e->position, offset)", "Vector2Add(deathPosition, offset)"),
        ("GrantXP(sourceTowerIndex, e->xpValue)", "GrantXP(sourceTowerIndex, deathXP)"),
        ("GrantHeroXP(e->xpValue)", "GrantHeroXP(deathXP)"),
        ("GrantHeroXP((int)(e->xpValue * 0.4f))", "GrantHeroXP((int)(deathXP * 0.4f))"),
    ):
        source = replace_once(source, before, after)
    # Retain this hit's data even if the successor occupies the same pool slot.
    # The snapshot lives through damage application and preserves RNG/call order.
    source = replace_once(
        source,
        "    // T4 Tesla Chain Logic\n"
        "    if (p->sourceType == TOWER_T4_TESLA_CHAIN && p->chainCount > 0) {",
        "    // T4 Tesla Chain Logic\n"
        "    Projectile impact;\n"
        "    if (p->sourceType == TOWER_T4_TESLA_CHAIN && p->chainCount > 0) {\n"
        "        impact = *p;\n"
        "        p = &impact;",
    )
    return source
