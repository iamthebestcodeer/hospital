#include "test.h"
static void exercise_pure_rules(void) {
    Enemy *enemy = test_enemy(0, 100, 100);
    ApplyStatusEffect(enemy, STATUS_BURN, 2, 5);
    ProcessStatusEffects(enemy, .01f);
    (void)CalculateDamage(100, DMG_PHYSICAL, enemy);
    (void)WorldToTile((Vector2){-1, 100});
    (void)ClosestPointOnSegment((Vector2){10, 5}, (Vector2){0, 0}, (Vector2){20, 0});
    (void)LerpAngle(350, 10, .5f);
}
static void exercise_gameplay_systems(void) {
    CHECK(PlaceTower(0, 0, TOWER_PULSE));
    SpawnEnemy(ENEMY_BASIC, (Vector2){100, 20});
    GrantXP(0, 150);
    GrantHeroXP(250);
    UpdateHero(.01f);
    UpdateTowers(.01f);
    UpdateEnemies(.01f);
    UpdateProjectiles(.01f);
    UpdateVFX(.01f);
    AddFloatingTextFmt((Vector2){0, 0}, WHITE, false, "%d %g", 42, 1.5);
    SellTower(0);
    ManageWaves(.01f);
    HandleInput();
}
static void domain_calls_preserve_all_system_v_callee_saved_registers(void) {
    CHECK(av_test_preserves_registers(exercise_pure_rules));
}
static void nested_gameplay_calls_preserve_all_system_v_callee_saved_registers(void) {
    CHECK(av_test_preserves_registers(exercise_gameplay_systems));
}
void suite_abi(void) {
    RUN(domain_calls_preserve_all_system_v_callee_saved_registers);
    RUN(nested_gameplay_calls_preserve_all_system_v_callee_saved_registers);
}
