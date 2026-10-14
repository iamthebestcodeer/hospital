#include "test.h"
static void vigor_adds_fifteen_damage_per_skill_point(void) {
    game.hero.skills[SKILL_VIGOR] = 3;
    ApplyHeroSkills();
    CHECK(game.hero.attackDamage == 80);
}
static void agility_improves_speed_and_reduces_dash_cooldown(void) {
    game.hero.skills[SKILL_AGILITY] = 1;
    ApplyHeroSkills();
    NEAR(game.hero.speed, 198, .0001f);
    NEAR(game.hero.dashCooldown, 5.4f, .0001f);
}
static void burst_mastery_improves_damage_and_range(void) {
    game.hero.skills[SKILL_BURST_MASTERY] = 2;
    ApplyHeroSkills();
    NEAR(game.hero.burstDamage, 140, .0001f);
    NEAR(game.hero.burstRange, 144, .0001f);
}
static void exact_hero_xp_threshold_awards_one_level_and_point(void) {
    GrantHeroXP(250);
    CHECK(game.hero.level == 2);
    CHECK(game.hero.xp == 0);
    CHECK(game.hero.xpToNextLevel == 400);
    CHECK(game.hero.skillPoints == 1);
}
static void large_hero_xp_grants_cross_multiple_thresholds(void) {
    GrantHeroXP(1000);
    CHECK(game.hero.level == 3);
    CHECK(game.hero.xp == 350);
    CHECK(game.hero.skillPoints == 2);
}
static void base_tower_xp_stops_at_level_three(void) {
    CHECK(PlaceTower(0, 0, TOWER_PULSE));
    GrantXP(0, 435);
    CHECK(game.towers[0].stats.level == 3);
    CHECK(game.towers[0].stats.xp == 0);
    GrantXP(-1, 100);
    GrantXP(100, 100);
    CHECK(game.towers[0].stats.level == 3);
}
static void specialized_towers_do_not_gain_xp(void) {
    game.gold = 10000;
    CHECK(PlaceTower(0, 0, TOWER_T4_PULSE_REPEATER));
    GrantXP(0, 1000);
    CHECK(game.towers[0].stats.xp == 0);
    CHECK(game.towers[0].stats.level == 1);
}
static void leadership_bonus_only_applies_near_the_hero(void) {
    CHECK(PlaceTower(0, 0, TOWER_PULSE));
    game.hero.skills[SKILL_LEADERSHIP] = 1;
    GrantXP(0, 100);
    CHECK(game.towers[0].stats.xp == 115);
    game.hero.position = (Vector2){900, 700};
    game.towers[0].stats.xp = 0;
    GrantXP(0, 100);
    CHECK(game.towers[0].stats.xp == 100);
}
void suite_progression(void) {
    RUN(vigor_adds_fifteen_damage_per_skill_point);
    RUN(agility_improves_speed_and_reduces_dash_cooldown);
    RUN(burst_mastery_improves_damage_and_range);
    RUN(exact_hero_xp_threshold_awards_one_level_and_point);
    RUN(large_hero_xp_grants_cross_multiple_thresholds);
    RUN(base_tower_xp_stops_at_level_three);
    RUN(specialized_towers_do_not_gain_xp);
    RUN(leadership_bonus_only_applies_near_the_hero);
}
