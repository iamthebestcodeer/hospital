#include "test.h"
static bool held[512], pressed[512], mouse_buttons[3];
static Vector2 mouse_position;
bool __wrap_IsKeyDown(int key) {
    return key >= 0 && key < 512 && held[key];
}
bool __wrap_IsKeyPressed(int key) {
    return key >= 0 && key < 512 && pressed[key];
}
bool __wrap_IsMouseButtonPressed(int button) {
    return button >= 0 && button < 3 && mouse_buttons[button];
}
Vector2 __wrap_GetMousePosition(void) {
    return mouse_position;
}
int __wrap_GetFPS(void) {
    return 60;
}
float __real_GetAimToleranceDegrees(TowerType type);
float __wrap_GetAimToleranceDegrees(TowerType type) {
    float result = __real_GetAimToleranceDegrees(type);
    /* Deliberately exercise the ABI: a callee may overwrite caller-saved XMM4. */
    __asm__ volatile("pxor %%xmm4, %%xmm4" ::: "xmm4");
    return result;
}
#ifndef TEST_REFERENCE
/* Renderer ports: gameplay tests never link src/generated/render.asm. */
void BuildStaticMapRT(void) {
}
Color GetTowerColor(TowerType type) {
    switch (type) {
    case TOWER_PULSE:
    case TOWER_T4_PULSE_REPEATER:
    case TOWER_T4_PULSE_SNIPER:
        return COLOR_ENERGY;
    case TOWER_CANNON:
    case TOWER_T4_CANNON_MORTAR:
    case TOWER_T4_CANNON_VULCAN:
        return COLOR_PHYSICAL;
    case TOWER_CRYO:
    case TOWER_T4_CRYO_BLIZZARD:
    case TOWER_T4_CRYO_FREEZER:
        return COLOR_CRYO;
    case TOWER_TESLA:
    case TOWER_T4_TESLA_CHAIN:
    case TOWER_T4_TESLA_STORM:
        return COLOR_TESLA;
    default:
        return GRAY;
    }
}
#endif
void test_reset(void) {
    memset(held, 0, sizeof held);
    memset(pressed, 0, sizeof pressed);
    memset(mouse_buttons, 0, sizeof mouse_buttons);
    mouse_position = (Vector2){-100, -100};
    memset(&game, 0, sizeof game);
    SetRandomSeed(1234);
    InitMap();
    ResetGame();
    game.state = GS_PLAYING;
    game.camera.zoom = 1;
    game.environmentColor = WHITE;
}
void test_hold(int key) {
    held[key] = true;
}
void test_press(int key) {
    pressed[key] = true;
}
void test_mouse(float x, float y, int button) {
    mouse_position = (Vector2){x, y};
    if (button >= 0 && button < 3)
        mouse_buttons[button] = true;
}
Enemy *test_enemy(int index, float x, float y) {
    Enemy *enemy = &game.enemies[index];
    memset(enemy, 0, sizeof *enemy);
    enemy->active = true;
    enemy->id = index + 1;
    enemy->position = (Vector2){x, y};
    enemy->hp = enemy->maxHp = 100;
    enemy->speed = enemy->baseSpeed = 80;
    enemy->waypointIndex = 1;
    return enemy;
}
int test_particle_count(void) {
    int count = 0;
    for (int i = 0; i < MAX_PARTICLES; i++)
        count += game.particles[i].active;
    return count;
}
int test_projectile_count(void) {
    int count = 0;
    for (int i = 0; i < MAX_PROJECTILES; i++)
        count += game.projectiles[i].active;
    return count;
}
