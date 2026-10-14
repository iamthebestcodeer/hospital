#include "test.h"
static Tower weapon(TowerType type) {
    Tower t = {0};
    t.active = true;
    t.type = type;
    t.stats.level = 1;
    ConfigureTowerStats(&t);
    return t;
}
static void each_projectile_weapon_uses_its_expected_speed(void) {
    const int types[] = {TOWER_PULSE,
                         TOWER_CANNON,
                         TOWER_TESLA,
                         TOWER_T4_PULSE_REPEATER,
                         TOWER_T4_PULSE_SNIPER,
                         TOWER_T4_CANNON_MORTAR,
                         TOWER_T4_CANNON_VULCAN,
                         TOWER_T4_TESLA_CHAIN,
                         TOWER_T4_TESLA_STORM};
    const float speeds[] = {650, 350, 900, 650, 1200, 250, 700, 900, 900};
    Enemy *e = test_enemy(0, 100, 100);
    for (unsigned i = 0; i < sizeof types / sizeof *types; i++) {
        game.towers[0] = weapon(types[i]);
        FireProjectile(&game.towers[0], e);
        NEAR(game.projectiles[i].speed, speeds[i], 0);
        CHECK(game.projectiles[i].targetEnemyId == e->id);
    }
}
static void stale_target_ids_deactivate_homing_projectiles(void) {
    Enemy *e = test_enemy(0, 100, 100);
    game.towers[0] = weapon(TOWER_PULSE);
    FireProjectile(&game.towers[0], e);
    e->id++;
    UpdateProjectiles(.1f);
    CHECK(!game.projectiles[0].active);
    NEAR(e->hp, 100, 0);
}
static void swept_collision_hits_a_target_without_overshooting(void) {
    Enemy *e = test_enemy(0, 100, 0);
    e->hp = 1000;
    game.towers[0] = weapon(TOWER_PULSE);
    FireProjectile(&game.towers[0], e);
    UpdateProjectiles(1);
    CHECK(!game.projectiles[0].active);
    NEAR(game.projectiles[0].position.x, 100, 0);
    CHECK(e->hp < 1000);
}
static void a_full_projectile_pool_preserves_existing_shots(void) {
    for (int i = 0; i < MAX_PROJECTILES; i++) {
        game.projectiles[i].active = true;
        game.projectiles[i].damage = 123;
    }
    Enemy *e = test_enemy(0, 100, 100);
    game.towers[0] = weapon(TOWER_PULSE);
    FireProjectile(&game.towers[0], e);
    CHECK(test_projectile_count() == 500);
    NEAR(game.projectiles[499].damage, 123, 0);
}
static void beams_do_not_create_active_projectiles(void) {
    Enemy *e = test_enemy(0, 100, 100);
    game.towers[0] = weapon(TOWER_CRYO);
    FireProjectile(&game.towers[0], e);
    CHECK(test_projectile_count() == 0);
}
static void critical_hits_double_damage_before_applying_statuses(void) {
    Enemy *e = test_enemy(0, 100, 100);
    e->hp = 1000;
    Projectile p = {0};
    p.damage = 50;
    p.damageType = DMG_TRUE;
    p.sourceTowerIndex = -1;
    ApplyDamageAndEffects(&p, e, true);
    NEAR(e->hp, 900, 0);
}
static void burn_projectiles_apply_burn_and_melted_armor_together(void) {
    Enemy *e = test_enemy(0, 100, 100);
    e->hp = 1000;
    Projectile p = {0};
    p.damage = 1;
    p.damageType = DMG_TRUE;
    p.sourceTowerIndex = -1;
    p.applyStatus = STATUS_BURN;
    p.statusDuration = 5;
    p.statusIntensity = 10;
    ApplyDamageAndEffects(&p, e, false);
    CHECK(e->statusCount == 2);
    CHECK(e->status[0].type == STATUS_MELTED_ARMOR);
    CHECK(e->status[1].type == STATUS_BURN);
}
static void area_damage_excludes_enemies_outside_the_radius(void) {
    Enemy *near = test_enemy(0, 49, 0), *far = test_enemy(1, 51, 0);
    near->hp = far->hp = 1000;
    Projectile p = {0};
    p.damage = 10;
    p.damageType = DMG_TRUE;
    p.aoeRadius = 50;
    p.sourceTowerIndex = -1;
    HandleProjectileImpact(&p, NULL);
    CHECK(near->hp < 1000);
    NEAR(far->hp, 1000, 0);
}
static void chain_lightning_does_not_retarget_an_enemy_in_its_history(void) {
    Enemy *first = test_enemy(0, 0, 0), *next = test_enemy(1, 100, 0);
    first->hp = next->hp = 1000;
    Projectile p = {0};
    p.damage = 10;
    p.damageType = DMG_ENERGY;
    p.sourceType = TOWER_T4_TESLA_CHAIN;
    p.chainCount = 1;
    p.sourceTowerIndex = -1;
    HandleProjectileImpact(&p, first);
    CHECK(test_projectile_count() == 1);
    CHECK(game.projectiles[0].targetEnemyId == next->id);
    CHECK(game.projectiles[0].chainCount == 0);
    CHECK(game.projectiles[0].hitHistory[0] == first->id);
}
void suite_projectiles(void) {
    RUN(each_projectile_weapon_uses_its_expected_speed);
    RUN(stale_target_ids_deactivate_homing_projectiles);
    RUN(swept_collision_hits_a_target_without_overshooting);
    RUN(a_full_projectile_pool_preserves_existing_shots);
    RUN(beams_do_not_create_active_projectiles);
    RUN(critical_hits_double_damage_before_applying_statuses);
    RUN(burn_projectiles_apply_burn_and_melted_armor_together);
    RUN(area_damage_excludes_enemies_outside_the_radius);
    RUN(chain_lightning_does_not_retarget_an_enemy_in_its_history);
}
