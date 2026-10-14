#define _POSIX_C_SOURCE 200809L
#include "aetherium.h"
#include <assert.h>
#include <stdint.h>
#include <stddef.h>
#include <inttypes.h>
#include <time.h>

/* Only input/time queries are controlled. Simulation, RNG and rendering use
   the actual game functions and actual Raylib/libm in both executables. */
static bool held[512], pressed[512], mousePressed[3];
static Vector2 mouse = {-100, -100};
bool __wrap_IsKeyDown(int k) {
    return k >= 0 && k < 512 && held[k];
}
bool __wrap_IsKeyPressed(int k) {
    return k >= 0 && k < 512 && pressed[k];
}
bool __wrap_IsMouseButtonPressed(int b) {
    return b >= 0 && b < 3 && mousePressed[b];
}
Vector2 __wrap_GetMousePosition(void) {
    return mouse;
}
int __wrap_GetFPS(void) {
    return 60;
}
static void no_input(void) {
    memset(held, 0, sizeof held);
    memset(pressed, 0, sizeof pressed);
    memset(mousePressed, 0, sizeof mousePressed);
    mouse = (Vector2){-100, -100};
}
static uint64_t hash_bytes(const void *data, size_t size) {
    uint64_t h = UINT64_C(14695981039346656037);
    const unsigned char *p = data;
    while (size--) {
        h ^= *p++;
        h *= UINT64_C(1099511628211);
    }
    return h;
}
static uint64_t state_hash(void) {
    static GameData copy;
    memcpy(&copy, &game, sizeof copy);
    /* Addresses/GL names aren't gameplay. Text contents are checked separately. */
    copy.tooltip.title = NULL;
    copy.tooltip.description = NULL;
    memset(&copy.mapRT, 0, sizeof copy.mapRT);
    uint64_t h = hash_bytes(&copy, sizeof copy);
    if (game.tooltip.title)
        h ^= hash_bytes(game.tooltip.title, strlen(game.tooltip.title));
    if (game.tooltip.description)
        h ^= hash_bytes(game.tooltip.description, strlen(game.tooltip.description));
    return h;
}
static void emit(const char *tag, int n) {
    printf("%s %d %016" PRIx64 "\n", tag, n, state_hash());
}
static void reset(unsigned seed) {
    no_input();
    memset(&game, 0, sizeof game);
    SetRandomSeed(seed);
    InitMap();
    ResetGame();
    game.camera.zoom = 1;
    game.environmentColor = WHITE;
}
static unsigned fixture_random(unsigned *s) {
    *s = *s * 1664525u + 1013904223u;
    return *s;
}
static int active_particles(void) {
    int n = 0;
    for (int i = 0; i < MAX_PARTICLES; i++)
        n += game.particles[i].active;
    return n;
}
static void floating_text_test(void) {
    reset(400);
    AddFloatingText((Vector2){10, 20}, "abc", BLUE, false);
    assert(!strcmp(game.floatingTexts[0].text, "abc"));
    for (int i = 3; i < 32; i++)
        assert(game.floatingTexts[0].text[i] == 0);
    emit("floating-text", 0);

    reset(401);
    AddFloatingText((Vector2){-10, 20}, "abcdefghijklmnopqrstuvwxyz0123456789", RED, true);
    assert(!strcmp(game.floatingTexts[0].text, "abcdefghijklmnopqrstuvwxyz01234"));
    emit("floating-text", 1);

    reset(402);
    AddFloatingTextFmt((Vector2){10, 20}, BLUE, true, "%d/%d/%d/%d/%d:%.1f/%.1f", 11, 22, 33, 44,
                       55, 1.25, 2.75);
    assert(!strcmp(game.floatingTexts[0].text, "11/22/33/44/55:1.2/2.8"));
    emit("floating-text", 2);

    reset(403);
    AddFloatingTextFmt((Vector2){10, 20}, GREEN, false, "%g/%g/%g/%g/%g/%g/%g/%g/%g", 1., 2., 3.,
                       4., 5., 6., 7., 8., 9.);
    assert(!strcmp(game.floatingTexts[0].text, "1/2/3/4/5/6/7/8/9"));
    emit("floating-text", 3);

    reset(404);
    for (int i = 0; i < MAX_FLOATING_TEXT; i++) {
        game.floatingTexts[i].active = true;
        game.floatingTexts[i].lifetime = 1.5f;
    }
    game.floatingTexts[71].lifetime = .125f;
    AddFloatingTextFmt((Vector2){10, 20}, GREEN, true, "replacement %d", 71);
    assert(!strcmp(game.floatingTexts[71].text, "replacement 71"));
    assert(game.floatingTexts[70].lifetime == 1.5f && game.floatingTexts[71].lifetime == 2);
    emit("floating-text", 4);

    reset(405);
    int expected = GetRandomValue(0, 1000000000);
    SetRandomSeed(405);
    for (int i = 0; i < MAX_FLOATING_TEXT; i++) {
        game.floatingTexts[i].active = true;
        game.floatingTexts[i].lifetime = 101;
    }
    AddFloatingTextFmt((Vector2){10, 20}, GREEN, false, "not allocated");
    assert(GetRandomValue(0, 1000000000) == expected);
    emit("floating-text", 5);
}
static void particles_test(void) {
    const int counts[] = {-7, 0, 1, 8, 30, 40, 100, 200, 250, 3000, 3001};
    int testcase = 0;
    for (unsigned seed = 1; seed <= 8; seed++)
        for (int pattern = 0; pattern < 8; pattern++)
            for (size_t c = 0; c < sizeof counts / sizeof *counts; c++)
                for (int gravity = 0; gravity < 2; gravity++) {
                    reset(seed);
                    unsigned local = seed;
                    int freeSlots = 0;
                    for (int i = 0; i < MAX_PARTICLES; i++) {
                        Particle *p = &game.particles[i];
                        p->position = (Vector2){i + 0.25f, -i - 0.5f};
                        p->life = 0.25f;
                        p->maxLife = 1.75f;
                        p->startSize = 3.5f;
                        p->endSize = 1;
                        switch (pattern) {
                        case 0:
                            p->active = false;
                            break;
                        case 1:
                            p->active = true;
                            break;
                        case 2:
                            p->active = i < 2900;
                            break;
                        case 3:
                            p->active = i % 2 == 0;
                            break;
                        case 4:
                            p->active = (fixture_random(&local) % 10) != 0;
                            break;
                        case 5:
                            p->active = i != 2999;
                            break;
                        case 6:
                            p->active = i != 0;
                            break;
                        default:
                            p->active = (fixture_random(&local) % 4) != 0;
                            break;
                        }
                        freeSlots += !p->active;
                    }
                    int before = active_particles();
                    SpawnParticles((Vector2){17.125f, -3.25f}, counts[c], (Color){1, 2, 3, 4},
                                   (Color){251, 252, 253, 254}, 173.875f, 7.375f, 1.625f, gravity);
                    int added = counts[c] > 0 ? counts[c] : 0;
                    if (added > freeSlots)
                        added = freeSlots;
                    assert(active_particles() == before + added);
                    emit("particles", testcase++);
                    /* Also prove the random stream hasn't been advanced differently. */
                    printf("rng %d %d\n", testcase, GetRandomValue(0, 1000000000));
                }
    /* Clearing/reusing slots across calls; both sides must pick lowest slot. */
    reset(99);
    for (int frame = 0; frame < 1000; frame++) {
        for (int i = frame % 17; i < MAX_PARTICLES; i += 17)
            game.particles[i].active = false;
        SpawnParticles((Vector2){frame, frame / 2}, frame % 301, RED, BLUE, 150, 10, 2, frame % 2);
        UpdateVFX(0.013f);
        emit("reuse", frame);
    }
}
static void vfx_test(void) {
    const float steps[] = {-0.05f, 0, 0.0001f, 1.0f / 144, 1.0f / 60, 0.1f, 0.25f};
    for (int pattern = 0; pattern < 5; pattern++)
        for (int step = 0; step < 7; step++) {
            reset(200 + pattern);
            unsigned fixture = pattern + 7;
            for (int i = 0; i < MAX_PARTICLES; i++) {
                Particle *p = &game.particles[i];
                p->active = pattern == 0   ? false
                            : pattern == 1 ? true
                                           : fixture_random(&fixture) % 4 != 0;
                p->gravity = fixture_random(&fixture) % 2;
                p->position = (Vector2){i * 0.25f, -i * 0.125f};
                p->velocity = (Vector2){(int)(fixture_random(&fixture) % 200) - 100,
                                        (int)(fixture_random(&fixture) % 200) - 100};
                p->life = (fixture_random(&fixture) % 100) / 100.0f;
                p->maxLife = 0.25f + (fixture_random(&fixture) % 100) / 50.0f;
            }
            for (int i = 0; i < MAX_FLOATING_TEXT; i++) {
                FloatingText *ft = &game.floatingTexts[i];
                ft->active = true;
                ft->position.y = i * 0.25f;
                ft->lifetime = i / 50.0f;
                ft->velocityY = -20 - i;
            }
            for (int f = 0; f < 30; f++) {
                UpdateVFX(steps[step]);
                emit("vfx", pattern * 210 + step * 30 + f);
            }
        }
}
static void feature_test(void) {
    for (int base = 0; base < 4; base++)
        for (int path = 0; path < 2; path++) {
            reset(42 + base);
            game.gold = 10000;
            game.aether = 1000;
            assert(!PlaceTower(0, 3, base));
            assert(!PlaceTower(-1, 0, base));
            int cost = GetTowerCost(base);
            assert(PlaceTower(0, 0, base));
            assert(game.gold == 10000 - cost);
            assert(!PlaceTower(0, 0, base));
            GrantXP(0, 2000);
            assert(game.towers[0].stats.level == 3);
            assert(!UpgradeTower(&game.towers[0], base));
            int type = 4 + base * 2 + path;
            assert(UpgradeTower(&game.towers[0], type));
            assert(game.towers[0].type == type);
            emit("upgrade", type);
            int gold = game.gold;
            SellTower(0);
            assert(game.gold == gold + (int)(cost * 0.6f));
            assert(!game.occupied[0][0]);
            emit("sell", type);
        }
    reset(21);
    game.currentWave = 20;
    for (int type = 0; type < 8; type++)
        SpawnEnemy(type, (Vector2){200 + type * 10, 140});
    for (int i = 0; i < 8; i++) {
        Enemy *e = &game.enemies[i];
        assert(e->type == (EnemyType)i && e->active && e->hp > 0);
        for (int s = 0; s < 6; s++)
            ApplyStatusEffect(e, 1 << s, 4, 0.75f + s * 0.1f);
        assert(e->statusCount == 6);
        ApplyStatusEffect(e, STATUS_SLOW, 10, 0.2f); /* weaker does not refresh */
        for (int d = 0; d < 3; d++)
            printf("damage %d %d %a\n", i, d, (double)CalculateDamage(80, d, e));
        ProcessStatusEffects(e, 0.2f);
    }
    emit("statuses", 0);
    for (int frame = 0; frame < 100; frame++) {
        UpdateEnemies(0.05f);
        emit("enemy", frame);
    }
    HandleEnemyDeath(5, -2);
    emit("spawner-death", 0);
    GrantHeroXP(100000);
    assert(game.hero.skillPoints > 0);
    for (int s = 0; s < 4; s++) {
        game.hero.skills[s] = 4;
        ApplyHeroSkills();
        emit("skill", s);
    }
    reset(54);
    game.state = GS_PLAYING;
    /* Exercise target modes, all tower weapons, AoE and chain history. */
    game.gold = 100000;
    game.currentWave = 50;
    game.hero.skillPoints = 0;
    for (int t = 0; t < 12; t++) {
        assert(PlaceTower(t + 1, 2, t));
        game.towers[t].stats.level = 3;
        ConfigureTowerStats(&game.towers[t]);
    }
    for (int i = 0; i < 60; i++)
        SpawnEnemy(i % 8, (Vector2){40 + (i % 24) * 35, 140 + (i / 24) * 25});
    for (int mode = 0; mode < 4; mode++) {
        for (int t = 0; t < 12; t++) {
            game.towers[t].targetingMode = mode;
            game.towers[t].targetIndex = -1;
            game.towers[t].targetEnemyId = -1;
        }
        for (int f = 0; f < 240; f++) {
            UpdateTowers(1.0f / 60);
            UpdateEnemies(1.0f / 60);
            UpdateProjectiles(1.0f / 60);
            UpdateVFX(1.0f / 60);
            emit("weapons", mode * 240 + f);
        }
    }
    /* Every wave tier including healer/spawner/boss, clear reward, life loss. */
    for (int wave = 1; wave <= 20; wave++) {
        reset(100 + wave);
        game.state = GS_PLAYING;
        game.currentWave = wave - 1;
        game.waveTimer = 0;
        ManageWaves(0.1f);
        assert(game.currentWave == wave);
        while (game.enemiesToSpawn > 0)
            ManageWaves(2.0f);
        emit("wave-spawns", wave);
        for (int i = 0; i < MAX_ENEMIES; i++)
            game.enemies[i].active = false;
        int gold = game.gold;
        ManageWaves(0.1f);
        assert(!game.waveActive && game.gold == gold + 50 + wave * 20);
        emit("wave-reward", wave);
    }
    reset(88);
    game.state = GS_PLAYING;
    game.lives = 1;
    SpawnEnemy(ENEMY_BASIC, game.map.waypoints[game.map.waypointCount - 1]);
    game.enemies[0].waypointIndex = game.map.waypointCount;
    UpdatePlaying(0.02f);
    assert(game.state == GS_GAME_OVER);
    pressed[KEY_R] = true;
    UpdateGame(0.02f);
    assert(game.state == GS_PLAYING && game.lives == 20);
    no_input();
    pressed[KEY_P] = true;
    UpdateGame(0.02f);
    assert(game.state == GS_PAUSED);
    UpdateGame(0.02f);
    assert(game.state == GS_PLAYING);
    emit("states", 0);
    game.state = GS_LEVEL_UP_HERO;
    game.hero.skillPoints = 1;
    UpdateHeroLevelUp(.016f);
    assert(game.state == GS_LEVEL_UP_HERO);
    game.hero.skillPoints = 0;
    UpdateHeroLevelUp(.016f);
    assert(game.state == GS_PLAYING);
    emit("skill-overlay-resume", 0);
}
static void scenario(unsigned seed, int towers, int enemies, int particles) {
    reset(seed);
    game.state = GS_PLAYING;
    game.gold = 1000000;
    game.aether = 100000;
    game.lives = 100000;
    game.currentWave = 20;
    game.waveActive = true;
    game.waveTimer = 100000;
    game.spawnTimer = 100000;
    game.enemiesToSpawn = 100000;
    int t = 0;
    for (int y = 0; y < MAP_HEIGHT && t < towers; y++)
        for (int x = 0; x < MAP_WIDTH && t < towers; x++)
            if (IsTileBuildable(x, y)) {
                assert(PlaceTower(x, y, t % 12));
                game.towers[t].stats.level = 3;
                ConfigureTowerStats(&game.towers[t]);
                game.towers[t].targetingMode = t % 4;
                t++;
            }
    memset(game.particles, 0, sizeof game.particles);
    for (int e = 0; e < enemies; e++) {
        SpawnEnemy(e % 8, (Vector2){60 + (e % 22) * 40, 130 + (e / 22) * 35});
        game.enemies[e].hp = game.enemies[e].maxHp = 50000;
        game.enemies[e].abilityTimer = 0.1f;
    }
    if (particles)
        SpawnParticles((Vector2){450, 400}, particles, RED, BLUE, 150, 10, 2, false);
    game.hero.position = (Vector2){440, 380};
}
static void simulation_test(void) {
    for (unsigned seed = 1; seed <= 4; seed++) {
        scenario(seed, 100, 300, 2500);
        for (int f = 0; f < 2400; f++) {
            no_input();
            held[KEY_SPACE] = f % 120 < 60;
            held[KEY_D] = f % 240 < 120;
            held[KEY_W] = f % 400 < 200;
            pressed[KEY_Q] = f % 360 == 0;
            pressed[KEY_E] = f % 1200 == 0;
            pressed[KEY_G] = f % 101 == 0;
            pressed[KEY_P] = f == 80 || f == 90;
            if (game.hero.skillPoints > 0) {
                game.hero.skills[f % 4]++;
                game.hero.skillPoints--;
                ApplyHeroSkills();
            }
            float dt = (float[]){1.0f / 60, 1.0f / 144, 0.033f, 0.1f}[f % 4];
            game.globalTime += dt;
            UpdateGame(dt);
            emit("simulation", seed * 2400 + f);
        }
    }
}
static double now(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}
static void window(void) {
    SetTraceLogLevel(LOG_WARNING);
    SetConfigFlags(FLAG_WINDOW_HIDDEN | FLAG_MSAA_4X_HINT);
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Aetherium verification");
    assert(IsWindowReady());
    SetExitKey(KEY_NULL);
}
static void screenshot(const char *dir, int frame) {
    char path[512];
    snprintf(path, sizeof path, "%s/frame-%02d.png", dir, frame);
    Image img = LoadImageFromScreen();
    assert(img.data);
    assert(ExportImage(img, path));
    UnloadImage(img);
}
static void render_test(const char *dir) {
    window();
    scenario(987, 24, 64, 1800);
    BuildStaticMapRT();
    for (int f = 0; f < 26; f++) {
        no_input();
        game.globalTime = 1 + f * 0.05f;
        game.state = GS_PLAYING;
        game.selectedTowerIndex = -1;
        game.placingTower = TOWER_NONE;
        if (f == 0)
            game.state = GS_TITLE;
        else if (f == 1)
            game.state = GS_PAUSED;
        else if (f == 2)
            game.state = GS_GAME_OVER;
        else if (f >= 3 && f <= 6) {
            game.state = GS_LEVEL_UP_HERO;
            game.hero.skillPoints = 4;
            mouse = (Vector2){400, 320 + (f - 3) * 65};
            mousePressed[0] = true;
        } else if (f >= 7 && f <= 18) {
            game.selectedTowerIndex = f - 7;
            mouse = (Vector2){1050, 650};
        } else if (f >= 19 && f <= 22) {
            game.placingTower = f - 19;
            mouse = (Vector2){400, 250};
            game.showGrid = true;
        } else if (f == 23) {
            game.selectedTowerIndex = 0;
            mouse = (Vector2){1050, 650};
            mousePressed[0] = true;
        } else if (f == 24) {
            game.selectedTowerIndex = 1;
            mouse = (Vector2){1050, 760};
            mousePressed[0] = true;
        } else {
            game.state = GS_TITLE;
            pressed[KEY_ENTER] = true;
            UpdateGame(0.016f);
        }
        DrawGame();
        screenshot(dir, f);
        emit("render", f);
    }
    UnloadRenderTexture(game.mapRT);
    CloseWindow();
}
/* Benchmarks include pool clearing/scenario setup on both sides and consume
   a final state hash, so all work is observable. RNG is the real Raylib RNG. */
static void bench_particles(const char *mode, int rounds) {
    reset(12345);
    int count = 250, occupancy = 0;
    if (!strcmp(mode, "spawn-dense"))
        occupancy = 2750;
    if (!strcmp(mode, "spawn-full")) {
        occupancy = 3000;
        count = 200;
    }
    if (!strcmp(mode, "spawn-small"))
        count = 8;
    if (!strcmp(mode, "spawn-one"))
        count = 1;
    if (!strcmp(mode, "spawn-zero"))
        count = 0;
    for (int i = 0; i < occupancy; i++)
        game.particles[i].active = true;
    double start = now();
    for (int r = 0; r < rounds; r++) {
        int end = occupancy + count;
        if (end > MAX_PARTICLES)
            end = MAX_PARTICLES;
        for (int i = occupancy; i < end; i++)
            game.particles[i].active = false;
        SpawnParticles((Vector2){400, 300}, count, RED, BLUE, 150, 10, 2, r % 2);
    }
    double elapsed = now() - start;
    printf("RESULT %s %d %.9f %016" PRIx64 "\n", mode, rounds, elapsed, state_hash());
}
static void bench_frames(const char *mode, int rounds) {
    bool render = !strncmp(mode, "render", 6);
    if (render)
        window();
    int towers = 100, enemies = 300, particles = 2500;
    if (!strcmp(mode, "idle")) {
        towers = 0;
        enemies = 0;
        particles = 0;
    }
    if (!strcmp(mode, "normal") || !strcmp(mode, "render-normal")) {
        towers = 12;
        enemies = 60;
        particles = 200;
    }
    if (!strcmp(mode, "vfx")) {
        towers = 0;
        enemies = 0;
        particles = 2750;
    }
    scenario(47, towers, enemies, particles);
    if (render)
        BuildStaticMapRT();
    double elapsed = 0;
    int left = rounds;
    while (left > 0) {
        /* Reconstruct the same active scene outside timed regions; short blocks
           prevent benchmarks from degenerating into an empty game. */
        bool rt = game.mapRTBuilt;
        RenderTexture2D texture = game.mapRT;
        scenario(47, towers, enemies, particles);
        game.mapRTBuilt = rt;
        game.mapRT = texture;
        int block = left < 120 ? left : 120;
        double start = now();
        for (int f = 0; f < block; f++) {
            no_input();
            held[KEY_SPACE] = true;
            pressed[KEY_E] = f == 0;
            pressed[KEY_Q] = f == 0;
            game.hero.skillPoints = 0;
            game.globalTime += 1.0f / 60;
            UpdateGame(1.0f / 60);
            if (!strcmp(mode, "vfx") && f % 12 == 0)
                SpawnParticles((Vector2){400, 300}, 250, RED, BLUE, 150, 10, 2, false);
            if (render) {
                if (!strcmp(mode, "render-title"))
                    game.state = GS_TITLE;
                DrawGame();
            }
        }
        elapsed += now() - start;
        left -= block;
    }
    printf("RESULT %s %d %.9f %016" PRIx64 "\n", mode, rounds, elapsed, state_hash());
    if (render) {
        UnloadRenderTexture(game.mapRT);
        CloseWindow();
    }
}
int main(int argc, char **argv) {
    SetTraceLogLevel(LOG_WARNING);
    if (argc < 2)
        return 2;
    if (!strcmp(argv[1], "verify")) {
        floating_text_test();
        particles_test();
        vfx_test();
        feature_test();
        simulation_test();
        return 0;
    }
    if (!strcmp(argv[1], "render") && argc == 3) {
        render_test(argv[2]);
        return 0;
    }
    if (!strcmp(argv[1], "bench") && argc == 4) {
        int rounds = atoi(argv[3]);
        if (rounds < 1)
            return 2;
        if (!strncmp(argv[2], "spawn-", 6))
            bench_particles(argv[2], rounds);
        else
            bench_frames(argv[2], rounds);
        return 0;
    }
    return 2;
}
