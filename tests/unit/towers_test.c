#include "test.h"
static void catalog_has_all_twelve_costs_and_aether_prices(void) {
    const int costs[] = {100, 250, 200, 400, 800, 1000, 1500, 900, 700, 850, 1100, 1300};
    for (int type = 0; type < 12; type++) {
        CHECK(GetTowerCost(type) == costs[type]);
        CHECK(GetTowerAetherCost(type) == (type < 4 ? 0 : 50 + costs[type] / 20));
    }
    CHECK(GetTowerCost(-1) == 99999);
    CHECK(GetTowerCost(99) == 99999);
}
static void placement_charges_gold_and_reserves_one_tile(void) {
    CHECK(PlaceTower(0, 0, TOWER_PULSE));
    CHECK(game.gold == 250);
    CHECK(game.occupied[0][0]);
    CHECK(game.towers[0].active);
    NEAR(game.towers[0].position.x, 20, 0);
    CHECK(game.towers[0].targetIndex == -1);
    CHECK(game.towers[0].totalCost == 100);
}
static void rejected_placement_preserves_resources(void) {
    CHECK(!PlaceTower(0, 3, TOWER_PULSE));
    CHECK(!PlaceTower(-1, 0, TOWER_PULSE));
    CHECK(!PlaceTower(0, 0, TOWER_TESLA));
    CHECK(game.gold == 350);
    CHECK(PlaceTower(0, 0, TOWER_PULSE));
    CHECK(!PlaceTower(0, 0, TOWER_PULSE));
    CHECK(game.gold == 250);
}
static void a_full_tower_pool_does_not_charge_for_a_failed_build(void) {
    for (int i = 0; i < MAX_TOWERS; i++)
        game.towers[i].active = true;
    CHECK(!PlaceTower(0, 0, TOWER_PULSE));
    CHECK(game.gold == 350);
    CHECK(!game.occupied[0][0]);
}
static void selling_refunds_sixty_percent_and_frees_the_tile(void) {
    CHECK(PlaceTower(0, 0, TOWER_PULSE));
    SellTower(0);
    CHECK(game.gold == 310);
    CHECK(!game.occupied[0][0]);
    CHECK(!game.towers[0].active);
    CHECK(game.selectedTowerIndex == -1);
    SellTower(0);
    SellTower(-1);
    SellTower(100);
    CHECK(game.gold == 310);
}
static void base_stats_scale_damage_range_and_rate(void) {
    Tower t = {0};
    t.type = TOWER_PULSE;
    t.stats.level = 3;
    ConfigureTowerStats(&t);
    NEAR(t.stats.damage, 34, .0001f);
    NEAR(t.stats.range, 180, .0001f);
    NEAR(t.stats.fireRate, 3.25f, .0001f);
    CHECK(t.stats.xpToNextLevel == 99999);
    CHECK(t.damageType == DMG_ENERGY);
}
static void beam_and_aura_rates_do_not_receive_attack_rate_scaling(void) {
    const int types[] = {TOWER_CRYO, TOWER_T4_CRYO_BLIZZARD, TOWER_T4_CRYO_FREEZER};
    const float rates[] = {0, .75f, 1.5f};
    for (int i = 0; i < 3; i++) {
        Tower t = {0};
        t.type = types[i];
        t.stats.level = 3;
        ConfigureTowerStats(&t);
        NEAR(t.stats.fireRate, rates[i], 0);
    }
}
static void every_specialization_accepts_only_its_own_base_tower(void) {
    CHECK(!UpgradeTower(NULL, TOWER_T4_PULSE_REPEATER));
    for (int base = 0; base < 4; base++)
        for (int branch = 0; branch < 2; branch++) {
            Tower t = {0};
            t.active = true;
            t.type = base;
            t.stats.level = 3;
            CHECK(!UpgradeTower(&t, 4 + ((base + 1) % 4) * 2));
            CHECK(t.type == base);
            CHECK(UpgradeTower(&t, 4 + base * 2 + branch));
            CHECK(t.type == 4 + base * 2 + branch);
        }
}
static void build_sell_round_trips_never_leave_occupied_grass(void) {
    game.gold = 1000000;
    for (int y = 0; y < MAP_HEIGHT; y++)
        for (int x = 0; x < MAP_WIDTH; x++)
            if (game.map.tiles[y][x] == 0) {
                int before = game.gold;
                CHECK(PlaceTower(x, y, TOWER_PULSE));
                SellTower(0);
                CHECK(!game.occupied[y][x]);
                CHECK(game.gold == before - 40);
            }
}
static void targeting_respects_aim_tolerance_across_module_calls(void) {
    CHECK(PlaceTower(0, 0, TOWER_PULSE));
    Tower *t = &game.towers[0];
    t->rotation = t->desiredRotation = 0;
    t->cooldownTimer = 0;
    test_enemy(0, 20, 100);
    UpdateTowers(.001f);
    CHECK(test_projectile_count() == 0); /* target is 90 degrees away */
    t->rotation = 90;
    t->cooldownTimer = 0;
    UpdateTowers(.001f);
    CHECK(test_projectile_count() == 1);
}
static int acquired_target(TargetingMode mode) {
    CHECK(PlaceTower(0, 0, TOWER_PULSE));
    game.towers[0].targetingMode = mode;
    Enemy *first = test_enemy(0, 100, 20), *advanced = test_enemy(1, 130, 20),
          *close = test_enemy(2, 60, 20);
    first->waypointIndex = 1;
    advanced->waypointIndex = 2;
    close->waypointIndex = 1;
    first->hp = 100;
    advanced->hp = 50;
    close->hp = 300;
    UpdateTowers(0);
    return game.towers[0].targetIndex;
}
static void first_target_mode_prefers_path_progress(void) {
    CHECK(acquired_target(TARGET_FIRST) == 1);
}
static void closest_target_mode_prefers_distance(void) {
    CHECK(acquired_target(TARGET_CLOSEST) == 2);
}
static void strongest_target_mode_prefers_highest_health(void) {
    CHECK(acquired_target(TARGET_STRONGEST) == 2);
}
static void weakest_target_mode_prefers_lowest_health(void) {
    CHECK(acquired_target(TARGET_WEAKEST) == 1);
}
static void stale_tower_target_handles_are_reacquired(void) {
    CHECK(PlaceTower(0, 0, TOWER_PULSE));
    Enemy *enemy = test_enemy(0, 100, 20);
    game.towers[0].targetIndex = 0;
    game.towers[0].targetEnemyId = 999;
    UpdateTowers(0);
    CHECK(game.towers[0].targetEnemyId == enemy->id);
}
static void an_out_of_range_target_is_replaced_with_a_reachable_one(void) {
    CHECK(PlaceTower(0, 0, TOWER_PULSE));
    test_enemy(0, 900, 20);
    Enemy *near = test_enemy(1, 100, 20);
    game.towers[0].targetIndex = 0;
    game.towers[0].targetEnemyId = 1;
    UpdateTowers(0);
    CHECK(game.towers[0].targetEnemyId == near->id);
}
static void aiming_across_the_signed_angle_boundary_still_fires(void) {
    const float rotations[] = {-170, 170, -190, 190};
    const float targets[] = {170, -170, 170, -170};
    for (unsigned i = 0; i < sizeof rotations / sizeof *rotations; i++) {
        test_reset();
        CHECK(PlaceTower(0, 0, TOWER_PULSE));
        Tower *tower = &game.towers[0];
        tower->position = (Vector2){200, 200};
        tower->rotation = rotations[i];
        test_enemy(0, 200 + 100 * cosf(targets[i] * DEG2RAD),
                   200 + 100 * sinf(targets[i] * DEG2RAD));
        UpdateTowers(0);
        CHECK(test_projectile_count() == 1);
    }
}
void suite_towers(void) {
    RUN(catalog_has_all_twelve_costs_and_aether_prices);
    RUN(placement_charges_gold_and_reserves_one_tile);
    RUN(rejected_placement_preserves_resources);
    RUN(a_full_tower_pool_does_not_charge_for_a_failed_build);
    RUN(selling_refunds_sixty_percent_and_frees_the_tile);
    RUN(base_stats_scale_damage_range_and_rate);
    RUN(beam_and_aura_rates_do_not_receive_attack_rate_scaling);
    RUN(every_specialization_accepts_only_its_own_base_tower);
    RUN(build_sell_round_trips_never_leave_occupied_grass);
    RUN(targeting_respects_aim_tolerance_across_module_calls);
    RUN(first_target_mode_prefers_path_progress);
    RUN(closest_target_mode_prefers_distance);
    RUN(strongest_target_mode_prefers_highest_health);
    RUN(weakest_target_mode_prefers_lowest_health);
    RUN(stale_tower_target_handles_are_reacquired);
    RUN(an_out_of_range_target_is_replaced_with_a_reachable_one);
    RUN(aiming_across_the_signed_angle_boundary_still_fires);
}
