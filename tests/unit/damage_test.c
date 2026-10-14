#include "test.h"
static void true_damage_bypasses_both_resistances(void) {
    Enemy *e = test_enemy(0, 0, 0);
    e->armor = 1000;
    e->energyResist = 2000;
    NEAR(CalculateDamage(75, DMG_TRUE, e), 75, 0);
}
static void physical_and_energy_use_their_own_resistance(void) {
    Enemy *e = test_enemy(0, 0, 0);
    e->armor = 100;
    e->energyResist = 300;
    NEAR(CalculateDamage(100, DMG_PHYSICAL, e), 50, 0);
    NEAR(CalculateDamage(100, DMG_ENERGY, e), 25, 0);
}
static void damage_never_falls_below_half_a_hit_point(void) {
    Enemy *e = test_enemy(0, 0, 0);
    NEAR(CalculateDamage(0, DMG_TRUE, e), .5f, 0);
    NEAR(CalculateDamage(-10, DMG_ENERGY, e), .5f, 0);
}
static void negative_resistance_is_clamped_away_from_division_by_zero(void) {
    Enemy *e = test_enemy(0, 0, 0);
    e->armor = -100;
    e->energyResist = -1000;
    NEAR(CalculateDamage(10, DMG_PHYSICAL, e), 1000, 0);
    NEAR(CalculateDamage(10, DMG_ENERGY, e), 1000, 0);
}
static void weaken_only_increases_energy_damage(void) {
    Enemy *e = test_enemy(0, 0, 0);
    ApplyStatusEffect(e, STATUS_WEAKEN, 6, 1.25f);
    NEAR(CalculateDamage(100, DMG_ENERGY, e), 125, 0);
    NEAR(CalculateDamage(100, DMG_PHYSICAL, e), 100, 0);
}
static void brittle_and_melted_armor_multiply_physical_damage(void) {
    Enemy *e = test_enemy(0, 0, 0);
    ApplyStatusEffect(e, STATUS_BRITTLE, 6, 1.5f);
    ApplyStatusEffect(e, STATUS_MELTED_ARMOR, 6, 1.2f);
    NEAR(CalculateDamage(100, DMG_PHYSICAL, e), 180, .0001f);
    NEAR(CalculateDamage(100, DMG_ENERGY, e), 100, 0);
}
static void slow_and_stun_do_not_change_damage(void) {
    Enemy *e = test_enemy(0, 0, 0);
    ApplyStatusEffect(e, STATUS_SLOW, 6, .8f);
    ApplyStatusEffect(e, STATUS_STUN, 6, 1);
    NEAR(CalculateDamage(100, DMG_PHYSICAL, e), 100, 0);
}
static void increasing_armor_cannot_increase_physical_damage(void) {
    Enemy *e = test_enemy(0, 0, 0);
    float previous = INFINITY;
    for (int armor = -99; armor <= 10000; armor++) {
        e->armor = (float)armor;
        float actual = CalculateDamage(100, DMG_PHYSICAL, e);
        CHECK(isfinite(actual));
        CHECK(actual >= .5f);
        CHECK(actual <= previous);
        previous = actual;
    }
}
void suite_damage(void) {
    RUN(true_damage_bypasses_both_resistances);
    RUN(physical_and_energy_use_their_own_resistance);
    RUN(damage_never_falls_below_half_a_hit_point);
    RUN(negative_resistance_is_clamped_away_from_division_by_zero);
    RUN(weaken_only_increases_energy_damage);
    RUN(brittle_and_melted_armor_multiply_physical_damage);
    RUN(slow_and_stun_do_not_change_damage);
    RUN(increasing_armor_cannot_increase_physical_damage);
}
