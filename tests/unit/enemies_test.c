#include "test.h"
static void spawning_uses_the_lowest_free_slot_and_unique_ids(void) {
    game.currentWave = 1;
    SpawnEnemy(ENEMY_BASIC, game.map.waypoints[0]);
    SpawnEnemy(ENEMY_FAST, game.map.waypoints[0]);
    CHECK(game.enemies[0].id == 1);
    CHECK(game.enemies[1].id == 2);
    game.enemies[0].active = false;
    SpawnEnemy(ENEMY_TANK, game.map.waypoints[0]);
    CHECK(game.enemies[0].id == 3);
    CHECK(game.enemies[0].type == ENEMY_TANK);
}
static void a_full_enemy_pool_does_not_consume_an_id(void) {
    for (int i = 0; i < MAX_ENEMIES; i++)
        game.enemies[i].active = true;
    int before = game.enemyIdCounter;
    SpawnEnemy(ENEMY_BASIC, (Vector2){0, 0});
    CHECK(game.enemyIdCounter == before);
}
static void every_enemy_type_has_positive_health_speed_and_rewards(void) {
    game.currentWave = 1;
    for (int type = 0; type < 8; type++) {
        SpawnEnemy(type, game.map.waypoints[0]);
        Enemy *e = &game.enemies[type];
        CHECK(e->active);
        CHECK(e->type == (EnemyType)type);
        CHECK(e->hp > 0);
        CHECK(e->speed > 0);
        CHECK(e->goldValue > 0);
    }
}
static void enemy_movement_consumes_distance_without_stopping_at_waypoints(void) {
    Enemy *e = test_enemy(0, 250, 140);
    e->waypointIndex = 1;
    UpdateEnemies(.25f);
    NEAR(e->position.x, 260, .0001f);
    NEAR(e->position.y, 150, .0001f);
    CHECK(e->waypointIndex == 2);
}
static void reaching_the_end_costs_exactly_one_life(void) {
    Enemy *e = test_enemy(0, 1020, 220);
    e->waypointIndex = game.map.waypointCount;
    UpdateEnemies(.016f);
    CHECK(!e->active);
    CHECK(game.lives == 19);
    UpdateEnemies(.016f);
    CHECK(game.lives == 19);
}
static void healer_pulse_heals_nearby_allies_but_not_distant_ones(void) {
    Enemy *healer = test_enemy(0, 100, 100);
    healer->type = ENEMY_HEALER;
    Enemy *near = test_enemy(1, 150, 100), *far = test_enemy(2, 500, 100);
    near->hp = far->hp = 50;
    game.currentWave = 1;
    UpdateEnemies(0);
    NEAR(near->hp, 100, 0);
    NEAR(far->hp, 50, 0);
    NEAR(healer->abilityTimer, 2, 0);
}
static void burn_death_is_processed_before_enemy_movement(void) {
    Enemy *e = test_enemy(0, 0, 140);
    e->hp = 1;
    ApplyStatusEffect(e, STATUS_BURN, 5, 10);
    UpdateEnemies(.2f);
    CHECK(!e->active);
    NEAR(e->position.x, 0, 0);
}
static void spawner_death_creates_four_minions(void) {
    game.currentWave = 1;
    SpawnEnemy(ENEMY_SPAWNER, (Vector2){250, 140});
    HandleEnemyDeath(0, -1);
    int minions = 0;
    for (int i = 0; i < MAX_ENEMIES; i++)
        minions += game.enemies[i].active && game.enemies[i].type == ENEMY_MINION;
    CHECK(minions == 4);
}
void suite_enemies(void) {
    RUN(spawning_uses_the_lowest_free_slot_and_unique_ids);
    RUN(a_full_enemy_pool_does_not_consume_an_id);
    RUN(every_enemy_type_has_positive_health_speed_and_rewards);
    RUN(enemy_movement_consumes_distance_without_stopping_at_waypoints);
    RUN(reaching_the_end_costs_exactly_one_life);
    RUN(healer_pulse_heals_nearby_allies_but_not_distant_ones);
    RUN(burn_death_is_processed_before_enemy_movement);
    RUN(spawner_death_creates_four_minions);
}
