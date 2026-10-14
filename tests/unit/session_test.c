#include "test.h"
static void reset_restores_resources_and_clears_entity_pools(void) {
    game.gold = 0;
    game.lives = 1;
    game.aether = 99;
    game.towers[99].active = true;
    game.enemies[299].active = true;
    game.projectiles[499].active = true;
    game.particles[2999].active = true;
    game.occupied[0][0] = true;
    ResetGame();
    CHECK(game.gold == 350);
    CHECK(game.lives == 20);
    CHECK(game.aether == 0);
    CHECK(!game.towers[99].active);
    CHECK(!game.enemies[299].active);
    CHECK(test_projectile_count() == 0);
    CHECK(test_particle_count() == 0);
    CHECK(!game.occupied[0][0]);
    CHECK(game.map.waypointCount == 13);
    CHECK(game.map.tiles[3][0] == 1);
}
static void enter_starts_a_fresh_game_from_the_title(void) {
    game.state = GS_TITLE;
    game.gold = 1;
    test_press(KEY_ENTER);
    UpdateGame(.016f);
    CHECK(game.state == GS_PLAYING);
    CHECK(game.gold == 350);
}
static void a_mouse_click_can_start_the_game(void) {
    game.state = GS_TITLE;
    test_mouse(400, 400, MOUSE_LEFT_BUTTON);
    UpdateGame(.016f);
    CHECK(game.state == GS_PLAYING);
}
static void pause_and_resume_do_not_advance_wave_simulation(void) {
    test_press(KEY_P);
    float timer = game.waveTimer;
    UpdateGame(.1f);
    CHECK(game.state == GS_PAUSED);
    NEAR(game.waveTimer, timer, 0);
    UpdateGame(.1f);
    CHECK(game.state == GS_PLAYING);
    NEAR(game.waveTimer, timer, 0);
}
static void skill_selection_resumes_only_after_the_last_point(void) {
    game.hero.skillPoints = 1;
    UpdatePlaying(.016f);
    CHECK(game.state == GS_LEVEL_UP_HERO);
    UpdateHeroLevelUp(.016f);
    CHECK(game.state == GS_LEVEL_UP_HERO);
    game.hero.skillPoints = 0;
    UpdateHeroLevelUp(.016f);
    CHECK(game.state == GS_PLAYING);
}
static void game_over_can_restart_with_full_resources(void) {
    game.lives = 0;
    UpdatePlaying(.016f);
    CHECK(game.state == GS_GAME_OVER);
    test_press(KEY_R);
    UpdateGame(.016f);
    CHECK(game.state == GS_PLAYING);
    CHECK(game.lives == 20);
}
static void build_shortcuts_and_cancel_update_selection(void) {
    test_press(KEY_TWO);
    HandleInput();
    CHECK(game.placingTower == TOWER_CANNON);
    test_reset();
    game.placingTower = TOWER_CANNON;
    game.selectedTowerIndex = 1;
    test_mouse(500, 500, MOUSE_RIGHT_BUTTON);
    HandleInput();
    CHECK(game.placingTower == TOWER_NONE);
    CHECK(game.selectedTowerIndex == -1);
}
static void grid_shortcut_toggles_the_grid(void) {
    test_press(KEY_G);
    HandleInput();
    CHECK(game.showGrid);
    HandleInput();
    CHECK(!game.showGrid);
}
static void next_wave_shortcut_starts_a_wave(void) {
    test_press(KEY_N);
    ManageWaves(.01f);
    CHECK(game.waveActive);
    CHECK(game.currentWave == 1);
    CHECK(game.enemiesToSpawn == 13);
}
static void cleared_wave_pays_resources_and_resets_the_timer(void) {
    game.currentWave = 3;
    game.waveActive = true;
    game.enemiesToSpawn = 0;
    ManageWaves(.01f);
    CHECK(!game.waveActive);
    CHECK(game.gold == 460);
    CHECK(game.aether == 6);
    NEAR(game.waveTimer, 25, 0);
}
static void camera_shake_is_removed_before_mouse_build_coordinates_are_used(void) {
    game.camera.offset.x = 40;
    game.placingTower = TOWER_PULSE;
    test_mouse(60, 20, MOUSE_LEFT_BUTTON);
    HandleInput();
    CHECK(game.occupied[0][0]);
    CHECK(!game.occupied[0][1]);
}
static void holding_shift_keeps_the_selected_build_tool(void) {
    game.placingTower = TOWER_PULSE;
    test_hold(KEY_LEFT_SHIFT);
    test_mouse(20, 20, MOUSE_LEFT_BUTTON);
    HandleInput();
    CHECK(game.occupied[0][0]);
    CHECK(game.placingTower == TOWER_PULSE);
}
static void late_wave_spawn_intervals_do_not_drop_below_the_minimum(void) {
    game.currentWave = 100;
    game.waveActive = true;
    game.enemiesToSpawn = 1;
    game.spawnTimer = 0;
    ManageWaves(.016f);
    NEAR(game.spawnTimer, .3f, 0);
    CHECK(game.enemies[0].type == ENEMY_BOSS);
}
void suite_session(void) {
    RUN(reset_restores_resources_and_clears_entity_pools);
    RUN(enter_starts_a_fresh_game_from_the_title);
    RUN(a_mouse_click_can_start_the_game);
    RUN(pause_and_resume_do_not_advance_wave_simulation);
    RUN(skill_selection_resumes_only_after_the_last_point);
    RUN(game_over_can_restart_with_full_resources);
    RUN(build_shortcuts_and_cancel_update_selection);
    RUN(grid_shortcut_toggles_the_grid);
    RUN(next_wave_shortcut_starts_a_wave);
    RUN(cleared_wave_pays_resources_and_resets_the_timer);
    RUN(camera_shake_is_removed_before_mouse_build_coordinates_are_used);
    RUN(holding_shift_keeps_the_selected_build_tool);
    RUN(late_wave_spawn_intervals_do_not_drop_below_the_minimum);
}
