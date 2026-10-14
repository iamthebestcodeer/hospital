#include "test.h"
static void horizontal_movement_uses_speed_times_delta(void) {
    test_hold(KEY_D);
    UpdateHero(.1f);
    NEAR(game.hero.position.x, 118, .0001f);
    NEAR(game.hero.position.y, 100, 0);
}
static void diagonal_movement_has_the_same_speed_as_horizontal_movement(void) {
    test_hold(KEY_D);
    test_hold(KEY_S);
    UpdateHero(.1f);
    Vector2 displacement = Vector2Subtract(game.hero.position, (Vector2){100, 100});
    NEAR(Vector2Length(displacement), 18, .0001f);
}
static void opposite_keys_cancel_movement(void) {
    test_hold(KEY_D);
    test_hold(KEY_A);
    test_hold(KEY_W);
    test_hold(KEY_S);
    UpdateHero(.1f);
    NEAR(game.hero.position.x, 100, 0);
    NEAR(game.hero.position.y, 100, 0);
}
static void movement_stays_inside_all_four_game_boundaries(void) {
    game.hero.position = (Vector2){-100, -100};
    UpdateHero(0);
    NEAR(game.hero.position.x, 10, 0);
    NEAR(game.hero.position.y, 10, 0);
    game.hero.position = (Vector2){2000, 2000};
    UpdateHero(0);
    NEAR(game.hero.position.x, 950, 0);
    NEAR(game.hero.position.y, 790, 0);
}
static void standing_dash_uses_last_facing_and_starts_a_cooldown(void) {
    test_press(KEY_Q);
    UpdateHero(.1f);
    NEAR(game.hero.position.x, 181, .0001f);
    NEAR(game.hero.dashTimer, .2f, 0);
    NEAR(game.hero.currentDashCooldown, 6, 0);
}
static void melee_only_hits_enemies_strictly_inside_its_range(void) {
    Enemy *near = test_enemy(0, 110, 100), *edge = test_enemy(1, 165, 100),
          *far = test_enemy(2, 200, 100);
    HeroAttack();
    NEAR(near->hp, 65, 0);
    NEAR(edge->hp, 100, 0);
    NEAR(far->hp, 100, 0);
}
static void burst_deals_true_damage_and_applies_weaken(void) {
    Enemy *e = test_enemy(0, 200, 100);
    e->hp = e->maxHp = 500;
    e->energyResist = 1000;
    test_press(KEY_E);
    UpdateHero(.016f);
    NEAR(e->hp, 400, 0);
    CHECK(e->statusCount == 1);
    CHECK(e->status[0].type == STATUS_WEAKEN);
    NEAR(game.hero.currentBurstCooldown, 20, 0);
}
static void cooldown_prevents_repeated_bursts(void) {
    Enemy *e = test_enemy(0, 200, 100);
    e->hp = e->maxHp = 500;
    test_press(KEY_E);
    UpdateHero(.016f);
    UpdateHero(.016f);
    NEAR(e->hp, 400, 0);
}
void suite_hero(void) {
    RUN(horizontal_movement_uses_speed_times_delta);
    RUN(diagonal_movement_has_the_same_speed_as_horizontal_movement);
    RUN(opposite_keys_cancel_movement);
    RUN(movement_stays_inside_all_four_game_boundaries);
    RUN(standing_dash_uses_last_facing_and_starts_a_cooldown);
    RUN(melee_only_hits_enemies_strictly_inside_its_range);
    RUN(burst_deals_true_damage_and_applies_weaken);
    RUN(cooldown_prevents_repeated_bursts);
}
