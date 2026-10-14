/*
 * Aetherium Vanguard - Initial Tower Defense RPG Hybrid
 * Language: C99
 * Library: Raylib (https://www.raylib.com/)
 * Compilation (UCRT64/MinGW):
 * gcc -o VanguardPrestige.exe geminit.c -Wall -Wextra -O3 -std=c99 -lraylib -lOpenGL32 -lgdi32 -lwinmm -lm
 */

#include "raylib.h"
#include "raymath.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <time.h>
#include <math.h>
// Include for va_list (used by formatted text)
#include <stdarg.h>
#include <float.h> // FLT_MAX for metric initialization

//----------------------------------------------------------------------------------
// Configuration Constants
//----------------------------------------------------------------------------------

#define SCREEN_WIDTH 1280
#define SCREEN_HEIGHT 800
#define GAME_AREA_WIDTH 960
#define UI_WIDTH (SCREEN_WIDTH - GAME_AREA_WIDTH)

#define TILE_SIZE 40
#define MAP_WIDTH (GAME_AREA_WIDTH / TILE_SIZE)
#define MAP_HEIGHT (SCREEN_HEIGHT / TILE_SIZE)

// Entity Limits
#define MAX_TOWERS 100
#define MAX_ENEMIES 300
#define MAX_PROJECTILES 500
#define MAX_PARTICLES 3000
#define MAX_FLOATING_TEXT 100
#define MAX_WAYPOINTS 50
// Define max chain hits for history tracking
#define MAX_CHAIN_HITS 10

// Game Balance
#define STARTING_LIVES 20
#define STARTING_GOLD 350
#define STARTING_AETHER 0
#define WAVE_INTERVAL 25.0f
#define TOWER_BASE_MAX_LEVEL 3 // Level before specialization

// Aesthetics (Deep Space Aetherium Theme)
#define COLOR_BG            (Color){ 10, 10, 20, 255 }
#define COLOR_UI_BG         (Color){ 20, 20, 35, 255 }
#define COLOR_UI_ACCENT     (Color){ 35, 35, 60, 255 }
#define COLOR_GRID          (Color){ 40, 40, 70, 100 }
#define COLOR_PATH          (Color){ 45, 30, 60, 255 }
#define COLOR_GRASS_1       (Color){ 15, 30, 25, 255 }
#define COLOR_GRASS_2       (Color){ 20, 35, 30, 255 }

// Damage/Tower Colors
#define COLOR_ENERGY        (Color){ 0, 220, 255, 255 } // Aether Blue
#define COLOR_PHYSICAL      (Color){ 255, 140, 0, 255 } // Deep Orange
#define COLOR_CRYO          (Color){ 135, 206, 250, 255 } // Light Sky Blue
#define COLOR_TESLA         (Color){ 255, 0, 255, 255 } // Magenta

// Resource Colors
#define COLOR_GOLD          (Color){ 255, 215, 0, 255 }
#define COLOR_AETHER_RES    (Color){ 180, 100, 255, 255 } // Purple (Hero/Aether)
#define COLOR_XP            (Color){ 50, 255, 50, 255 } // Green XP

#define COLOR_DANGER        (Color){ 255, 50, 50, 255 }
#define COLOR_TEXT_PRIMARY  (Color){ 245, 245, 255, 255 }
#define COLOR_TEXT_MUTED    (Color){ 150, 150, 180, 255 }

//----------------------------------------------------------------------------------
// Enums and Structures
//----------------------------------------------------------------------------------

typedef enum {
    GS_TITLE,
    GS_PLAYING,
    GS_PAUSED,
    GS_GAME_OVER,
    GS_LEVEL_UP_HERO // State for Hero skill selection
} GameState;

typedef enum {
    // Base Towers (Tier 1-3)
    TOWER_NONE = -1,
    TOWER_PULSE,
    TOWER_CANNON,
    TOWER_CRYO,
    TOWER_TESLA,

    // Tier 4 Specializations
    TOWER_T4_PULSE_REPEATER, // Extreme fire rate
    TOWER_T4_PULSE_SNIPER,   // Long range, high damage

    TOWER_T4_CANNON_MORTAR,  // Global range, massive AoE
    TOWER_T4_CANNON_VULCAN,  // High speed physical Gatling

    TOWER_T4_CRYO_BLIZZARD,  // AoE slow field
    TOWER_T4_CRYO_FREEZER,   // Beam that completely freezes

    TOWER_T4_TESLA_CHAIN,    // Chains lightning
    TOWER_T4_TESLA_STORM,    // Calls down lightning strikes
} TowerType;

typedef enum {
    ENEMY_BASIC,
    ENEMY_FAST,
    ENEMY_TANK,
    ENEMY_ETHEREAL,
    ENEMY_HEALER,
    ENEMY_SPAWNER,
    ENEMY_MINION,
    ENEMY_BOSS
} EnemyType;

typedef enum {
    DMG_PHYSICAL,
    DMG_ENERGY,
    DMG_TRUE
} DamageType;

// RPG Status Effects
typedef enum {
    STATUS_NONE = 0,
    STATUS_SLOW = 1 << 0,
    STATUS_BURN = 1 << 1,       // Damage over time
    STATUS_STUN = 1 << 2,       // Cannot move or act (includes Freeze)
    STATUS_WEAKEN = 1 << 3,     // Takes increased energy damage
    STATUS_BRITTLE = 1 << 4,    // Takes increased physical damage (Cryo Synergy)
    STATUS_MELTED_ARMOR = 1 << 5 // Takes increased physical damage (Burn Synergy)
} StatusEffect;

typedef struct {
    StatusEffect type;
    float duration;
    float intensity;
    float timer;
} ActiveStatus;

#define MAX_STATUS_EFFECTS 6

// --- Data Structures ---

// UI Tooltip System
typedef struct {
    bool visible;
    const char* title;
    const char* description;
    Rectangle bounds;
} Tooltip;

typedef struct {
    Vector2 position;
    char text[32];
    Color color;
    float lifetime;
    float velocityY;
    bool active;
    bool critical;
} FloatingText;

typedef struct {
    Vector2 position;
    Vector2 velocity;
    Color startColor;
    Color endColor;
    float life;
    float maxLife;
    float startSize;
    float endSize;
    bool active;
    bool gravity;
} Particle;

typedef struct {
    Vector2 position;
    float speed;
    float damage;
    DamageType damageType;
    float aoeRadius;
    TowerType sourceType;
    int sourceTowerIndex;

    // O(1) target: keep both index and id to validate quickly
    int targetIndex;
    int targetEnemyId;

    // For ballistic projectiles (Mortars).
    Vector2 targetPosition;

    bool active;
    int chainCount; // For Tesla Chain

    // Track hit history
    int hitHistory[MAX_CHAIN_HITS];
    int hitCount;

    // Status application
    StatusEffect applyStatus;
    float statusDuration;
    float statusIntensity;
} Projectile;

typedef struct Enemy {
    Vector2 position;
    EnemyType type;
    int id;
    // Use float for HP for fractional damage calculation
    float hp;
    float maxHp;
    float speed;
    float baseSpeed;
    float armor;
    float energyResist;
    int goldValue;
    int aetherValue;
    int xpValue;
    int waypointIndex;
    bool active;
    float abilityTimer;

    ActiveStatus status[MAX_STATUS_EFFECTS];
    int statusCount;
} Enemy;

typedef struct {
    int level;
    int xp;
    int xpToNextLevel;
    float damage;
    float range;
    float fireRate; // Attacks per second (or DPS/Aura intensity/Freeze duration)
} TowerStats;

typedef enum {
    TARGET_FIRST,
    TARGET_CLOSEST,
    TARGET_STRONGEST,
    TARGET_WEAKEST
} TargetingMode;
#define NUM_TARGETING_MODES 4

typedef struct {
    Vector2 position;
    TowerType type;
    TowerStats stats;
    DamageType damageType;
    float cooldownTimer;

    // O(1) target: keep both index and id to validate quickly
    int targetIndex;
    int targetEnemyId;

    float rotation;
    float desiredRotation;
    float visualRecoil;
    bool active;
    TargetingMode targetingMode;
    int kills;
    int totalCost;
} Tower;

// Hero Skill Tree
typedef enum {
    SKILL_VIGOR,        // Increased attack damage
    SKILL_AGILITY,      // Faster movement, reduced dash cooldown
    SKILL_BURST_MASTERY, // Increased burst damage and range
    SKILL_LEADERSHIP    // Towers near the hero gain XP faster
} HeroSkill;
#define NUM_HERO_SKILLS 4

typedef struct {
    Vector2 position;
    int level;
    int xp;
    int xpToNextLevel;
    int skillPoints;
    float speed;
    int attackDamage;
    float attackRange;
    float attackCooldown;
    float currentCooldown;
    // Abilities
    float dashCooldown;
    float currentDashCooldown;

    // Variables for dash implementation
    float dashTimer;
    Vector2 dashDirection;
    Vector2 lastMovementDirection;

    float burstCooldown;
    float currentBurstCooldown;
    float burstDamage;
    float burstRange;

    // Skill levels
    int skills[NUM_HERO_SKILLS];
} Hero;

typedef struct {
    int tiles[MAP_HEIGHT][MAP_WIDTH]; // 0=Grass, 1=Path
    Vector2 waypoints[MAX_WAYPOINTS];
    int waypointCount;
} GameMap;

// Global Game Data
typedef struct {
    GameState state;
    GameMap map;
    Hero hero;
    Camera2D camera; // Needed for screen shake and environment effects

    Tower towers[MAX_TOWERS];
    Enemy enemies[MAX_ENEMIES];
    Projectile projectiles[MAX_PROJECTILES];
    Particle particles[MAX_PARTICLES];
    FloatingText floatingTexts[MAX_FLOATING_TEXT];

    int lives;
    int gold;
    int aether;
    int currentWave;
    float waveTimer;
    int enemiesToSpawn;
    float spawnTimer;
    bool waveActive;

    // UI State
    TowerType placingTower;
    int selectedTowerIndex;
    bool showGrid;
    int enemyIdCounter;
    float globalTime;
    Tooltip tooltip;

    // VFX State
    float screenShakeIntensity;
    float screenShakeTime;
    // Store initial duration
    float screenShakeDuration;
    float dayNightCycle;
    Color environmentColor;

    // Static map render target
    RenderTexture2D mapRT;
    bool mapRTBuilt;

    // O(1) buildability checks
    bool occupied[MAP_HEIGHT][MAP_WIDTH];
} GameData;

GameData game = {0};

//----------------------------------------------------------------------------------
// Function Prototypes (Organized)
//----------------------------------------------------------------------------------

// Initialization and Setup
void InitGame(void);
void InitMap(void);
void ResetGame(void);
void BuildStaticMapRT(void);

// Game Loop
void UpdateGame(float dt);
void DrawGame(void);

// State Updates
void UpdatePlaying(float dt);
void UpdateHeroLevelUp(float dt);

// Core Logic Updates
void UpdateHero(float dt);
void HeroAttack(void);
void ApplyHeroSkills(void);
void UpdateTowers(float dt);
void UpdateEnemies(float dt);
void UpdateProjectiles(float dt);
void ManageWaves(float dt);
void HandleInput(void);
void UpdateEnvironment(float dt);

// Entity Management
void SpawnEnemy(EnemyType type, Vector2 position);
bool PlaceTower(int x, int y, TowerType type);
void SellTower(int towerIndex);
bool UpgradeTower(Tower* t, TowerType newType);
void ConfigureTowerStats(Tower* tower);
void FireProjectile(Tower* tower, Enemy* target);
void HandleProjectileImpact(Projectile* p, Enemy* primaryTarget);
void ApplyDamageAndEffects(Projectile* p, Enemy* target, bool isCritical);

// Drawing Functions
void DrawMap(void);
void DrawEntities(void);
void DrawTowers(void);
void DrawEnemies(void);
void DrawHero(void);
void DrawProjectiles(void);

// UI Drawing
void DrawUI(void);
void DrawHeroStatus(void);
void DrawBuildMenu(void);
void DrawTowerInspector(void);
void DrawTowerUpgradePaths(Tower* t);
void DrawTooltip(void);
void SetTooltip(const char* title, const char* description, Rectangle bounds);

// RPG Systems
void GrantXP(int towerIndex, int xp);
void GrantHeroXP(int xp);
void LevelUpTower(int towerIndex);
void LevelUpHero(void);
void HandleEnemyDeath(int enemyIndex, int sourceTowerIndex);
float CalculateDamage(float baseDamage, DamageType type, Enemy* target);
void ApplyStatusEffect(Enemy* enemy, StatusEffect type, float duration, float intensity);
void ProcessStatusEffects(Enemy* enemy, float dt);

// VFX and Aesthetics
void UpdateVFX(float dt);
void DrawVFX(void);
void SpawnParticles(Vector2 position, int count, Color startColor, Color endColor, float speed, float sizeStart, float sizeEnd, bool gravity);
void AddFloatingText(Vector2 position, const char* text, Color color, bool critical);
void ScreenShake(float intensity, float duration);
// Add prototype for formatted floating text.
void AddFloatingTextFmt(Vector2 position, Color color, bool critical, const char* fmt, ...);

// Utility Functions
Vector2 WorldToTile(Vector2 worldPos);
Vector2 TileToWorldCenter(int x, int y);
// Helper function for pathfinding
Vector2 ClosestPointOnSegment(Vector2 p, Vector2 a, Vector2 b);
bool IsTileBuildable(int x, int y);
int GetTowerCost(TowerType type);
int GetTowerAetherCost(TowerType type);
const char* GetTowerName(TowerType type);
const char* GetTowerDescription(TowerType type);
Color GetTowerColor(TowerType type);
Enemy* GetEnemyById(int id);
int GetEnemyIndexById(int id);
float LerpAngle(float start, float end, float amount);
// Aim tolerance per tower type
float GetAimToleranceDegrees(TowerType type);
// ColorLerp is in raymath.h

// GUI Helper
bool GuiButton(Rectangle bounds, const char* text, bool selected, bool enabled);
static inline Enemy* GetEnemyFromPair(int index, int id);

//----------------------------------------------------------------------------------
// Main Entry Point
//----------------------------------------------------------------------------------

int main(void) {
    // Initialization
    SetConfigFlags(FLAG_MSAA_4X_HINT);
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Aetherium Vanguard - PRESTIGE EDITION v3.1.0 (Physics, Movement & Pathfinding Fixed)");

    // We remove SetTargetFPS(60) or set it high to test frame-rate independence.
    // SetTargetFPS(60);
    SetRandomSeed((unsigned int)time(NULL));

    InitGame();

    // Main game loop
    while (!WindowShouldClose()) {
        // Update
        float dt = GetFrameTime();
        if (dt > 0.1f) dt = 0.1f; // Clamp dt

        game.globalTime += dt;
        UpdateGame(dt);

        // Draw
        DrawGame();
    }

    // De-Initialization
    if (game.mapRTBuilt) UnloadRenderTexture(game.mapRT);
    CloseWindow();

    return 0;
}

//----------------------------------------------------------------------------------
// Initialization Implementation
//----------------------------------------------------------------------------------

void InitGame(void) {
    InitMap();
    ResetGame();
    game.state = GS_TITLE;

    // Initialize Camera for screen shake/effects
    game.camera.target = (Vector2){ 0, 0 };
    game.camera.offset = (Vector2){ 0, 0 };
    game.camera.rotation = 0.0f;
    game.camera.zoom = 1.0f;

    BuildStaticMapRT();
}

void ResetGame(void) {
    memset(game.towers, 0, sizeof(game.towers));
    memset(game.enemies, 0, sizeof(game.enemies));
    memset(game.projectiles, 0, sizeof(game.projectiles));
    memset(game.particles, 0, sizeof(game.particles));
    memset(game.floatingTexts, 0, sizeof(game.floatingTexts));
    memset(game.occupied, 0, sizeof(game.occupied));

    game.lives = STARTING_LIVES;
    game.gold = STARTING_GOLD;
    game.aether = STARTING_AETHER;
    game.currentWave = 0;
    game.waveTimer = 10.0f;
    game.waveActive = false;
    game.placingTower = TOWER_NONE;
    game.selectedTowerIndex = -1;
    game.showGrid = false;
    game.enemyIdCounter = 1;
    game.dayNightCycle = 0.0f; // Start at Noon
    game.screenShakeDuration = 0.0f; // Initialize

    // Init Hero
    Hero* h = &game.hero;
    memset(h, 0, sizeof(Hero));
    h->position = (Vector2){ 100, 100 };
    h->level = 1;
    h->xpToNextLevel = 250;
    // Base stats (recalculated in ApplyHeroSkills)
    h->attackRange = 65.0f;
    h->attackCooldown = 0.6f;
    h->dashCooldown = 6.0f;
    h->burstCooldown = 20.0f;
    // Initialize default direction
    h->lastMovementDirection = (Vector2){1, 0};
    ApplyHeroSkills();
}

void InitMap(void) {
    // Initialize grass
    for (int y = 0; y < MAP_HEIGHT; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            game.map.tiles[y][x] = 0;
        }
    }

    // Define a complex S-shaped path
    int pathCoords[][2] = {
        {0, 3}, {1, 3}, {2, 3}, {3, 3}, {4, 3}, {5, 3}, {6, 3},
        {6, 4}, {6, 5}, {6, 6}, {6, 7}, {6, 8}, {6, 9},
        {5, 9}, {4, 9}, {3, 9}, {2, 9},
        {2, 10}, {2, 11}, {2, 12}, {2, 13}, {2, 14},
        {3, 14}, {4, 14}, {5, 14}, {6, 14}, {7, 14}, {8, 14}, {9, 14}, {10, 14}, {11, 14},
        {11, 13}, {11, 12}, {11, 11}, {11, 10}, {11, 9}, {11, 8}, {11, 7},
        {12, 7}, {13, 7}, {14, 7}, {15, 7}, {16, 7}, {17, 7},
        {17, 8}, {17, 9}, {17, 10}, {17, 11}, {17, 12},
        {18, 12}, {19, 12}, {20, 12}, {21, 12},
        {21, 11}, {21, 10}, {21, 9}, {21, 8}, {21, 7}, {21, 6}, {21, 5},
        {22, 5}, {23, 5}
    };

    int numPathTiles = sizeof(pathCoords) / sizeof(pathCoords[0]);

    for (int i = 0; i < numPathTiles; i++) {
        int x = pathCoords[i][0];
        int y = pathCoords[i][1];
        if (x >= 0 && x < MAP_WIDTH && y >= 0 && y < MAP_HEIGHT) {
            game.map.tiles[y][x] = 1; // Path
        }
    }

    // Generate Waypoints based on direction changes
    game.map.waypointCount = 0;
    // Start slightly off-screen
    game.map.waypoints[game.map.waypointCount++] = TileToWorldCenter(-2, 3);

    for (int i = 0; i < numPathTiles; i++) {
        bool directionChanged = false;
        if (i > 0 && i < numPathTiles - 1) {
            int dx_prev = pathCoords[i][0] - pathCoords[i-1][0];
            int dy_prev = pathCoords[i][1] - pathCoords[i-1][1];
            int dx_next = pathCoords[i+1][0] - pathCoords[i][0];
            int dy_next = pathCoords[i+1][1] - pathCoords[i][1];

            if (dx_prev != dx_next || dy_prev != dy_next) {
                directionChanged = true;
            }
        }

        if (directionChanged || i == numPathTiles - 1) {
             if (game.map.waypointCount < MAX_WAYPOINTS) {
                game.map.waypoints[game.map.waypointCount++] = TileToWorldCenter(pathCoords[i][0], pathCoords[i][1]);
            }
        }
    }
    // End slightly off-screen
    if (game.map.waypointCount < MAX_WAYPOINTS) {
        game.map.waypoints[game.map.waypointCount++] = TileToWorldCenter(MAP_WIDTH + 1, 5);
    }
}

void BuildStaticMapRT(void) {
    if (game.mapRTBuilt) return;

    game.mapRT = LoadRenderTexture(GAME_AREA_WIDTH, SCREEN_HEIGHT);
    BeginTextureMode(game.mapRT);
    // Base gradient once (no per-tile tinting here)
    DrawRectangleGradientV(0, 0, GAME_AREA_WIDTH, SCREEN_HEIGHT,
                           COLOR_BG, ColorBrightness(COLOR_BG, 0.1f));

    // Draw the tiles once, no environment tint
    for (int y = 0; y < MAP_HEIGHT; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            Rectangle tileRect = {(float)x * TILE_SIZE, (float)y * TILE_SIZE, TILE_SIZE, TILE_SIZE};
            Color tileColor;
            if (game.map.tiles[y][x] == 1) {
                tileColor = COLOR_PATH;
            } else {
                tileColor = ((x + y) % 2 == 0) ? COLOR_GRASS_1 : COLOR_GRASS_2;
            }
            DrawRectangleRec(tileRect, tileColor);

            if (game.map.tiles[y][x] == 1) {
                Color edgeGlow = Fade(COLOR_AETHER_RES, 0.4f);
                if (y > 0 && game.map.tiles[y-1][x] == 0) DrawLineEx((Vector2){tileRect.x, tileRect.y}, (Vector2){tileRect.x+TILE_SIZE, tileRect.y}, 2.0f, edgeGlow);
                if (y < MAP_HEIGHT-1 && game.map.tiles[y+1][x] == 0) DrawLineEx((Vector2){tileRect.x, tileRect.y+TILE_SIZE}, (Vector2){tileRect.x+TILE_SIZE, tileRect.y+TILE_SIZE}, 2.0f, edgeGlow);
                if (x > 0 && game.map.tiles[y][x-1] == 0) DrawLineEx((Vector2){tileRect.x, tileRect.y}, (Vector2){tileRect.x, tileRect.y+TILE_SIZE}, 2.0f, edgeGlow);
                if (x < MAP_WIDTH-1 && game.map.tiles[y][x+1] == 0) DrawLineEx((Vector2){tileRect.x+TILE_SIZE, tileRect.y}, (Vector2){tileRect.x+TILE_SIZE, tileRect.y+TILE_SIZE}, 2.0f, edgeGlow);
            }
        }
    }
    EndTextureMode();

    game.mapRTBuilt = true;
}

//----------------------------------------------------------------------------------
// Update Implementation (Game Loop and States)
//----------------------------------------------------------------------------------

void UpdateGame(float dt) {
    // Global updates
    UpdateEnvironment(dt);
    UpdateVFX(dt);
    game.tooltip.visible = false; // Reset tooltip every frame

    switch (game.state) {
        case GS_TITLE:
            if (IsKeyPressed(KEY_ENTER) || IsMouseButtonPressed(MOUSE_LEFT_BUTTON)) {
                ResetGame();
                game.state = GS_PLAYING;
            }
            break;
        case GS_PLAYING:
            UpdatePlaying(dt);
            break;
        case GS_PAUSED:
            if (IsKeyPressed(KEY_P) || IsKeyPressed(KEY_ESCAPE)) game.state = GS_PLAYING;
            HandleInput(); // Allow inspecting UI when paused
            break;
        case GS_LEVEL_UP_HERO:
            UpdateHeroLevelUp(dt);
            break;
        case GS_GAME_OVER:
             if (IsKeyPressed(KEY_R)) {
                 ResetGame();
                 game.state = GS_PLAYING;
             }
            break;
    }
}

void UpdatePlaying(float dt) {
    if (IsKeyPressed(KEY_P)) {
        game.state = GS_PAUSED;
        return;
    }

    // Check if Hero leveled up and needs to select skills
    if (game.hero.skillPoints > 0) {
        game.state = GS_LEVEL_UP_HERO;
        return;
    }

    HandleInput();

    ManageWaves(dt);
    UpdateHero(dt);
    UpdateTowers(dt);
    UpdateEnemies(dt);
    UpdateProjectiles(dt);

    if (game.lives <= 0) {
        game.lives = 0;
        if (game.state != GS_GAME_OVER) {
            game.state = GS_GAME_OVER;
            ScreenShake(20.0f, 2.0f);
        }
    }
}

// Update Environment (Day/Night Cycle and Screen Shake)
void UpdateEnvironment(float dt) {
    // --- Day/Night Cycle ---
    // Cycle time: 120 seconds for a full day/night cycle
    float cycleSpeed = 1.0f / 120.0f;
    game.dayNightCycle += dt * cycleSpeed;
    if (game.dayNightCycle >= 2.0f) game.dayNightCycle -= 2.0f;

    // Calculate light level (0.0 = Darkest, 1.0 = Brightest)
    float lightLevel = (cosf(game.dayNightCycle * PI) + 1.0f) / 2.0f;

    // Define the colors for day and night
    Color dayColor = WHITE;
    Color nightColor = (Color){ 80, 80, 150, 255 }; // Bluish tint

    // Interpolate environment color, clamping minimum brightness
    float clampedLightLevel = Clamp(lightLevel, 0.4f, 1.0f);
    game.environmentColor = ColorLerp(nightColor, dayColor, clampedLightLevel);

    // --- Screen Shake (Camera Update) ---
    if (game.screenShakeTime > 0) {
        game.screenShakeTime -= dt;
        // Intensity fades over time
        float normalizedTime = Clamp(game.screenShakeTime / game.screenShakeDuration, 0.0f, 1.0f);
        float intensity = game.screenShakeIntensity * normalizedTime;

        if (intensity < 0) intensity = 0;

        game.camera.offset.x = (float)GetRandomValue(-(int)intensity, (int)intensity);
        game.camera.offset.y = (float)GetRandomValue(-(int)intensity, (int)intensity);
    } else {
        // Smoothly return camera offset to origin
        game.camera.offset.x = Lerp(game.camera.offset.x, 0, 10.0f * dt);
        game.camera.offset.y = Lerp(game.camera.offset.y, 0, 10.0f * dt);
    }
}


void UpdateHeroLevelUp(float dt) {
    (void)dt; // Unused
    // Input handling is done within the DrawGame loop (IMGUI style) when this state is active.
    if (game.hero.skillPoints == 0) {
        game.state = GS_PLAYING;
    }
}

void HandleInput(void) {
    if (IsKeyPressed(KEY_G)) game.showGrid = !game.showGrid;

    // Mouse input needs to be adjusted by the camera offset (for screen shake)
    Vector2 mousePosScreen = GetMousePosition();
    Vector2 mousePosWorld = GetScreenToWorld2D(mousePosScreen, game.camera);

    if (mousePosScreen.x < GAME_AREA_WIDTH) {
        Vector2 tilePos = WorldToTile(mousePosWorld);
        int tileX = (int)tilePos.x;
        int tileY = (int)tilePos.y;

        if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON)) {
            if (game.placingTower != TOWER_NONE) {
                // Attempt to place tower
                if (PlaceTower(tileX, tileY, game.placingTower)) {
                    // Success
                    if (!IsKeyDown(KEY_LEFT_SHIFT) && !IsKeyDown(KEY_RIGHT_SHIFT)) {
                        game.placingTower = TOWER_NONE;
                    }
                }
            } else {
                // Attempt to select tower
                game.selectedTowerIndex = -1;
                for (int i = 0; i < MAX_TOWERS; i++) {
                    if (game.towers[i].active) {
                        // Check collision with the tower base rectangle
                        Rectangle towerRect = {game.towers[i].position.x - TILE_SIZE/2, game.towers[i].position.y - TILE_SIZE/2, TILE_SIZE, TILE_SIZE};
                        if (CheckCollisionPointRec(mousePosWorld, towerRect)) {
                            game.selectedTowerIndex = i;
                            break;
                        }
                    }
                }
            }
        }
    }

    if (IsMouseButtonPressed(MOUSE_RIGHT_BUTTON) || (IsKeyPressed(KEY_ESCAPE) && game.state != GS_PAUSED && game.state != GS_LEVEL_UP_HERO)) {
        game.placingTower = TOWER_NONE;
        game.selectedTowerIndex = -1;
    }

    // Keyboard shortcuts
    if (IsKeyPressed(KEY_ONE)) { game.placingTower = TOWER_PULSE; game.selectedTowerIndex = -1; }
    if (IsKeyPressed(KEY_TWO)) { game.placingTower = TOWER_CANNON; game.selectedTowerIndex = -1; }
    if (IsKeyPressed(KEY_THREE)) { game.placingTower = TOWER_CRYO; game.selectedTowerIndex = -1; }
    if (IsKeyPressed(KEY_FOUR)) { game.placingTower = TOWER_TESLA; game.selectedTowerIndex = -1; }
}

//----------------------------------------------------------------------------------
// Update Implementation (Hero Logic and Skills)
//----------------------------------------------------------------------------------

// Apply passive bonuses from the Hero's skill tree
void ApplyHeroSkills(void) {
    Hero* h = &game.hero;

    // Reset stats to base level values (we recalculate based on level + skills)
    float baseSpeed = 180.0f + (h->level - 1) * 5.0f;
    int baseAttack = 35 + (h->level - 1) * 10;
    float baseDashCD = 6.0f * powf(0.95f, (float)(h->level - 1));
    float baseBurstDmg = 100.0f + (h->level - 1) * 25.0f;
    float baseBurstRange = 120.0f + (h->level - 1) * 5.0f;

    // Apply Skills
    // SKILL_VIGOR: +15 Attack Damage per level
    h->attackDamage = baseAttack + h->skills[SKILL_VIGOR] * 15;

    // SKILL_AGILITY: +10% Speed, -10% Dash CD per level
    h->speed = baseSpeed * (1.0f + h->skills[SKILL_AGILITY] * 0.1f);
    h->dashCooldown = baseDashCD * powf(0.9f, (float)h->skills[SKILL_AGILITY]);

    // SKILL_BURST_MASTERY: +20% Burst Damage, +10% Burst Range per level
    h->burstDamage = baseBurstDmg * (1.0f + h->skills[SKILL_BURST_MASTERY] * 0.2f);
    h->burstRange = baseBurstRange * (1.0f + h->skills[SKILL_BURST_MASTERY] * 0.1f);

    // SKILL_LEADERSHIP: Applied when granting XP (see GrantXP)
}

void UpdateHero(float dt) {
    Hero* h = &game.hero;

    // Reworked movement and dash logic.

    // 1. Capture Input (WASD)
    Vector2 movementInput = {0, 0};
    if (IsKeyDown(KEY_W)) movementInput.y -= 1;
    if (IsKeyDown(KEY_S)) movementInput.y += 1;
    if (IsKeyDown(KEY_A)) movementInput.x -= 1;
    if (IsKeyDown(KEY_D)) movementInput.x += 1;

    if (Vector2Length(movementInput) > 0) {
        movementInput = Vector2Normalize(movementInput);
        h->lastMovementDirection = movementInput; // Update facing direction
    }

    // 2. Handle Dash (Q) Timers
    h->currentDashCooldown -= dt;
    h->dashTimer -= dt;

    float currentSpeed = h->speed;
    Vector2 moveVector = {0, 0};

    if (h->dashTimer > 0) {
        // Currently Dashing
        currentSpeed *= 4.5f;
        moveVector = h->dashDirection;
    } else {
        // Normal movement or initiating dash
        moveVector = movementInput;

        if (IsKeyPressed(KEY_Q) && h->currentDashCooldown <= 0) {
            // Start Dash
            h->dashTimer = 0.2f; // Duration
            h->currentDashCooldown = h->dashCooldown;

            // Determine direction: Current input, or last known direction if standing still.
            if (Vector2Length(movementInput) > 0) {
                h->dashDirection = movementInput;
            } else {
                h->dashDirection = h->lastMovementDirection;
            }

            // Apply movement for the first frame of the dash
            moveVector = h->dashDirection;
            currentSpeed *= 4.5f;

            SpawnParticles(h->position, 30, COLOR_AETHER_RES, Fade(COLOR_AETHER_RES, 0.0f), 80.0f, 8.0f, 2.0f, false);
        }
    }

    // 3. Apply Movement
    if (Vector2Length(moveVector) > 0) {
        h->position = Vector2Add(h->position, Vector2Scale(moveVector, currentSpeed * dt));
    }

    // Constrain to game area
    h->position.x = Clamp(h->position.x, 10, GAME_AREA_WIDTH - 10);
    h->position.y = Clamp(h->position.y, 10, SCREEN_HEIGHT - 10);

    // Basic Attack (Space)
    h->currentCooldown -= dt;
    if (IsKeyDown(KEY_SPACE) && h->currentCooldown <= 0) {
        HeroAttack();
        h->currentCooldown = h->attackCooldown;
    }

    // Ability 2: Aether Burst (E) - AoE Damage and Weaken
    h->currentBurstCooldown -= dt;
    if (IsKeyPressed(KEY_E) && h->currentBurstCooldown <= 0) {
        AddFloatingText(h->position, "AETHER BURST!", COLOR_ENERGY, true);
        ScreenShake(5.0f, 0.3f);

        // Massive particle explosion (Aesthetic improvement)
        SpawnParticles(h->position, 200, COLOR_ENERGY, Fade(WHITE, 0.5f), 150.0f, 10.0f, 2.0f, false);
        SpawnParticles(h->position, 50, COLOR_AETHER_RES, Fade(COLOR_AETHER_RES, 0.0f), 50.0f, 15.0f, 5.0f, false);

        for (int i = 0; i < MAX_ENEMIES; i++) {
            if (game.enemies[i].active) {
                if (Vector2Distance(h->position, game.enemies[i].position) <= h->burstRange) {
                    // Deal damage (True damage for the burst)
                    float actualDamage = CalculateDamage(h->burstDamage, DMG_TRUE, &game.enemies[i]);
                    // Apply float damage
                    game.enemies[i].hp -= actualDamage;
                    // Use formatted text helper
                    AddFloatingTextFmt(game.enemies[i].position, COLOR_ENERGY, true, "%.0f", actualDamage);

                    // Apply Weaken status effect (Increased Energy damage taken)
                    ApplyStatusEffect(&game.enemies[i], STATUS_WEAKEN, 6.0f, 1.25f); // 25% increase

                    if (game.enemies[i].hp <= 0) {
                        // Attribute kill to hero (Source Tower Index = -2)
                        HandleEnemyDeath(i, -2);
                    }
                }
            }
        }
        h->currentBurstCooldown = h->burstCooldown;
    }
}

void HeroAttack() {
    Hero* h = &game.hero;

    // Find enemies in range (Melee AoE)
    for (int i = 0; i < MAX_ENEMIES; i++) {
        if (game.enemies[i].active) {
            float dist = Vector2Distance(h->position, game.enemies[i].position);
            if (dist < h->attackRange) {
                 // Apply damage (Hero deals physical damage)
                float actualDamage = CalculateDamage((float)h->attackDamage, DMG_PHYSICAL, &game.enemies[i]);
                // Apply float damage
                game.enemies[i].hp -= actualDamage;
                // Use formatted text helper
                AddFloatingTextFmt(game.enemies[i].position, COLOR_AETHER_RES, false, "%.0f", actualDamage);

                // Visual feedback (slash effect - particle burst)
                SpawnParticles(game.enemies[i].position, 8, COLOR_AETHER_RES, Fade(WHITE, 0.0f), 100.0f, 5.0f, 1.0f, false);

                if (game.enemies[i].hp <= 0) {
                    // Handle death, attributing kill to the hero (Source Tower Index = -2)
                    HandleEnemyDeath(i, -2);
                }
            }
        }
    }
}

//----------------------------------------------------------------------------------
// Update Implementation (Towers, Enemies, Projectiles)
//----------------------------------------------------------------------------------

// Aim tolerance per tower type
float GetAimToleranceDegrees(TowerType type) {
    switch (type) {
        case TOWER_T4_PULSE_REPEATER:
        case TOWER_T4_CANNON_VULCAN:
        case TOWER_PULSE:
            return 30.0f; // forgiving for spray/high ROF
        case TOWER_T4_PULSE_SNIPER:
        case TOWER_CANNON:
        case TOWER_T4_CANNON_MORTAR:
            return 12.0f; // precise hitters
        case TOWER_CRYO:
        case TOWER_T4_CRYO_FREEZER:
            return 15.0f; // beams feel snappy but not jittery
        default:
            return 20.0f;
    }
}

void UpdateTowers(float dt) {
    for (int i = 0; i < MAX_TOWERS; i++) {
        if (!game.towers[i].active) continue;
        Tower* t = &game.towers[i];
        t->cooldownTimer -= dt;
        t->visualRecoil = Lerp(t->visualRecoil, 0.0f, 10.0f * dt);

        // --- Special Aura Logic (T4 Cryo Blizzard) ---
        if (t->type == TOWER_T4_CRYO_BLIZZARD) {
            // Continuously apply slow and brittle in an AoE
            for (int j = 0; j < MAX_ENEMIES; j++) {
                if (game.enemies[j].active && Vector2Distance(t->position, game.enemies[j].position) <= t->stats.range) {
                    // Intensity (Slow %) is stored in fireRate for aura towers
                    ApplyStatusEffect(&game.enemies[j], STATUS_SLOW, dt * 1.5f, t->stats.fireRate);
                    // Synergy: Apply Brittle
                    ApplyStatusEffect(&game.enemies[j], STATUS_BRITTLE, dt * 1.5f, 1.2f); // 20% increased physical dmg

                    // Apply minor DPS
                    float damage = t->stats.damage * dt;
                    float actualDamage = CalculateDamage(damage, t->damageType, &game.enemies[j]);
                    // Apply float damage
                    game.enemies[j].hp -= actualDamage;
                    if (game.enemies[j].hp <= 0) {
                        HandleEnemyDeath(j, i);
                    }
                }
            }
            continue; // Blizzard tower doesn't use standard targeting
        }


        // Validate current target in O(1)
        Enemy* target = GetEnemyFromPair(t->targetIndex, t->targetEnemyId);
        bool hasGlobalRange = (t->stats.range >= SCREEN_WIDTH * 2.0f);

        if (target) {
            if (!hasGlobalRange) {
                float rangeSqr = t->stats.range * t->stats.range;
                float distSqr = Vector2DistanceSqr(t->position, target->position);
                if (distSqr > rangeSqr) target = NULL;
            }
        }
        if (!target) {
            t->targetIndex = -1;
            t->targetEnemyId = -1;
        }

        // Acquire new target if needed
        if (!target) {
            int bestTargetIndex = -1;
            float bestMetricPrimary = -1.0f;
            float bestMetricSecondary = FLT_MAX;
            float rangeSqr = hasGlobalRange ? FLT_MAX : (t->stats.range * t->stats.range);

            for (int j = 0; j < MAX_ENEMIES; j++) {
                if (!game.enemies[j].active) continue;
                float distSqr = Vector2DistanceSqr(t->position, game.enemies[j].position);
                if (!hasGlobalRange && distSqr > rangeSqr) continue;

                bool better = false;
                switch (t->targetingMode) {
                    case TARGET_FIRST: {
                        float currentPrimary = (float)game.enemies[j].waypointIndex;
                        float currentSecondary = FLT_MAX;
                        if (game.enemies[j].waypointIndex < game.map.waypointCount) {
                            currentSecondary = Vector2DistanceSqr(game.enemies[j].position,
                                                                  game.map.waypoints[game.enemies[j].waypointIndex]);
                        }
                        if (bestTargetIndex == -1) better = true;
                        else if (currentPrimary > bestMetricPrimary) better = true;
                        else if (currentPrimary == bestMetricPrimary && currentSecondary < bestMetricSecondary) better = true;
                        if (better) { bestMetricPrimary = currentPrimary; bestMetricSecondary = currentSecondary; }
                    } break;
                    case TARGET_CLOSEST: {
                        if (bestTargetIndex == -1 || distSqr < bestMetricSecondary) {
                            better = true; bestMetricSecondary = distSqr;
                        }
                    } break;
                    case TARGET_STRONGEST: {
                        float currentPrimary = game.enemies[j].hp;
                        if (bestTargetIndex == -1 || currentPrimary > bestMetricPrimary) {
                            better = true; bestMetricPrimary = currentPrimary;
                        }
                    } break;
                    case TARGET_WEAKEST: {
                        float currentSecondary = game.enemies[j].hp;
                        if (bestTargetIndex == -1 || currentSecondary < bestMetricSecondary) {
                            better = true; bestMetricSecondary = currentSecondary;
                        }
                    } break;
                }
                if (better) bestTargetIndex = j;
            }

            if (bestTargetIndex != -1) {
                t->targetIndex = bestTargetIndex;
                t->targetEnemyId = game.enemies[bestTargetIndex].id;
                target = &game.enemies[bestTargetIndex];
            }
        }

        // Rotation/firing logic
        if (target) {
            Vector2 direction = Vector2Subtract(target->position, t->position);
            t->desiredRotation = atan2f(direction.y, direction.x) * RAD2DEG;

            float rotationSpeed = 18.0f;
            if (t->type == TOWER_T4_PULSE_SNIPER || t->type == TOWER_CANNON || t->type == TOWER_T4_CANNON_MORTAR) rotationSpeed = 8.0f;
            float rotAlpha = fminf(rotationSpeed * dt, 1.0f);
            t->rotation = LerpAngle(t->rotation, t->desiredRotation, rotAlpha);

            float angleDiff = fabsf(fmodf(t->rotation - t->desiredRotation + 180.0f, 360.0f) - 180.0f);
            float aimTolerance = GetAimToleranceDegrees(t->type);

            if (t->cooldownTimer <= 0 && (angleDiff <= aimTolerance || hasGlobalRange)) {
                if (t->type == TOWER_CRYO || t->type == TOWER_T4_CRYO_FREEZER) {
                    // Beam DPS
                    if (t->type == TOWER_CRYO) {
                        ApplyStatusEffect(target, STATUS_SLOW, dt * 1.5f, 0.6f);
                        ApplyStatusEffect(target, STATUS_BRITTLE, dt * 1.5f, 1.15f);
                    } else { // T4 Freezer
                        ApplyStatusEffect(target, STATUS_STUN, t->stats.fireRate, 1.0f);
                    }
                    float damage = t->stats.damage * dt;
                    float actualDamage = CalculateDamage(damage, t->damageType, target);
                    target->hp -= actualDamage;

                    if (target->hp <= 0) {
                        int targetIndex = (int)(target - game.enemies);
                        HandleEnemyDeath(targetIndex, i);
                    }
                } else {
                    FireProjectile(t, target);
                    if (t->type == TOWER_CANNON || t->type == TOWER_T4_CANNON_MORTAR || t->type == TOWER_T4_CANNON_VULCAN) t->visualRecoil = 8.0f;
                    else t->visualRecoil = 4.0f;

                    t->cooldownTimer = (t->stats.fireRate > 0) ? (1.0f / t->stats.fireRate) : 1.0f;
                }
            }
        } else {
            t->desiredRotation = 0.0f;
            if (t->stats.range < SCREEN_WIDTH * 2) {
                float rotAlphaIdle = fminf(5.0f * dt, 1.0f);
                t->rotation = LerpAngle(t->rotation, t->desiredRotation, rotAlphaIdle);
            }
        }
    }
}


void UpdateEnemies(float dt) {
    for (int i = 0; i < MAX_ENEMIES; i++) {
        if (!game.enemies[i].active) continue;

        Enemy* e = &game.enemies[i];

        // Handle status effects (DoT, Speed calculation)
        ProcessStatusEffects(e, dt);

        // Healer Aura Logic
        if (e->type == ENEMY_HEALER) {
            e->abilityTimer -= dt;
            if (e->abilityTimer <= 0) {
                e->abilityTimer = 2.0f; // Heal pulse every 2 seconds
                float healAmount = 50.0f + game.currentWave * 5.0f;
                float healRange = 100.0f;

                for (int j = 0; j < MAX_ENEMIES; j++) {
                    if (game.enemies[j].active && i != j && Vector2Distance(e->position, game.enemies[j].position) <= healRange) {
                        if (game.enemies[j].hp < game.enemies[j].maxHp) {
                            // Apply float healing
                            game.enemies[j].hp += healAmount;
                            if (game.enemies[j].hp > game.enemies[j].maxHp) game.enemies[j].hp = game.enemies[j].maxHp;
                            AddFloatingTextFmt(game.enemies[j].position, GREEN, false, "+%.0f HP", healAmount);
                        }
                    }
                }
                SpawnParticles(e->position, 10, GREEN, Fade(GREEN, 0.0f), 50.0f, 5.0f, 1.0f, false);
            }
        }

        // Check if died from DoT (e.g. Burn)
        if (e->hp <= 0) {
             HandleEnemyDeath(i, -1); // Source -1 means DoT or environment
             continue;
        }

        // Movement Logic
        // Logic to handle movement and prevent overshoot at waypoints.
        if (e->speed > 0) {
            float moveDistRemaining = e->speed * dt;

            // Use a loop to consume the movement distance, handling waypoint transitions smoothly.
            // This prevents the "stop-and-go" motion at waypoints by allowing movement continuation in the same frame.
            while (moveDistRemaining > 0.0f && e->waypointIndex < game.map.waypointCount) {
                Vector2 target = game.map.waypoints[e->waypointIndex];
                Vector2 direction = Vector2Subtract(target, e->position);
                float distanceToTarget = Vector2Length(direction);

                // Check for floating point inaccuracies, treat very small distances as zero
                if (distanceToTarget < 0.001f) {
                    e->position = target;
                    e->waypointIndex++;
                    continue; // Proceed to the next waypoint immediately
                }

                if (distanceToTarget <= moveDistRemaining) {
                    // Reached the waypoint. Move exactly to it.
                    e->position = target;
                    // Consume the distance traveled.
                    moveDistRemaining -= distanceToTarget;
                    // Advance to the next waypoint and continue the loop with remaining movement.
                    e->waypointIndex++;
                } else {
                    // Did not reach the waypoint this step. Move towards it.
                    // Normalize direction (we already checked distanceToTarget > 0.001f)
                    direction = Vector2Normalize(direction);

                    e->position = Vector2Add(e->position, Vector2Scale(direction, moveDistRemaining));
                    // Consumed all remaining movement.
                    moveDistRemaining = 0.0f;
                }
            }
        }

        // Check if reached the end
        if (e->waypointIndex >= game.map.waypointCount) {
            game.lives--;
            e->active = false;
            SpawnParticles(e->position, 50, COLOR_DANGER, COLOR_DANGER, 100.0f, 10.0f, 2.0f, false);
            ScreenShake(5.0f, 0.3f);
        }
    }
}

void UpdateProjectiles(float dt) {
    for (int i = 0; i < MAX_PROJECTILES; i++) {
        if (!game.projectiles[i].active) continue;

        Projectile* p = &game.projectiles[i];

        Enemy* targetEnemy = NULL;
        Vector2 currentTargetPos = {0};
        bool targetIsReachable = false;

        if (p->sourceType == TOWER_T4_CANNON_MORTAR) {
            currentTargetPos = p->targetPosition;
            targetIsReachable = true;
            targetEnemy = GetEnemyFromPair(p->targetIndex, p->targetEnemyId);
        } else {
            targetEnemy = GetEnemyFromPair(p->targetIndex, p->targetEnemyId);
            if (targetEnemy) {
                currentTargetPos = targetEnemy->position;
                targetIsReachable = true;
            }
        }


        // Movement and Collision Logic
        if (targetIsReachable) {
            // Collision radius depends on projectile type
            float collisionRadius = 10.0f;
            if (p->sourceType == TOWER_CANNON || p->sourceType == TOWER_T4_CANNON_MORTAR) collisionRadius = 15.0f;
            if (p->sourceType == TOWER_T4_PULSE_SNIPER) collisionRadius = 5.0f;

            Vector2 toTarget = Vector2Subtract(currentTargetPos, p->position);
            float distanceToTarget = Vector2Length(toTarget);
            float travelThisFrame = p->speed * dt;

            // Swept collision: if we can reach or pass the target this frame, impact immediately
            if (distanceToTarget <= travelThisFrame + collisionRadius) {
                p->position = currentTargetPos;
                p->active = false;

                // Determine the primary target for HandleProjectileImpact.
                Enemy* primaryImpactTarget = targetEnemy;

                if (p->sourceType == TOWER_T4_CANNON_MORTAR) {
                    if (primaryImpactTarget == NULL || !primaryImpactTarget->active || Vector2Distance(p->position, primaryImpactTarget->position) > p->aoeRadius) {
                        primaryImpactTarget = NULL;
                    }
                } else {
                    if (primaryImpactTarget == NULL || !primaryImpactTarget->active) {
                        primaryImpactTarget = NULL;
                    }
                }

                HandleProjectileImpact(p, primaryImpactTarget);
                continue;
            }

            // Move towards the target
            Vector2 direction = (distanceToTarget > 0.001f) ? Vector2Scale(toTarget, 1.0f / distanceToTarget) : (Vector2){0};
            Vector2 velocity = Vector2Scale(direction, travelThisFrame);
            p->position = Vector2Add(p->position, velocity);
        } else {
            // Target lost (only relevant for homing projectiles where the target died mid-flight), deactivate projectile.
            p->active = false;
        }
    }
}

//----------------------------------------------------------------------------------
// Game Logic Helpers Implementation (Combat and Effects)
//----------------------------------------------------------------------------------

void HandleProjectileImpact(Projectile* p, Enemy* primaryTarget) {

    // Visual Feedback (Explosions/Particles)
    Color particleColor = GetTowerColor(p->sourceType);
    int particleCount = 15;
    float particleSpeed = 60.0f;
    float particleSize = 5.0f;
    bool gravity = (p->damageType == DMG_PHYSICAL);

    if (p->aoeRadius > 0) {
        // AoE Impact (Cannon, Mortar)
        particleCount = 60;
        particleSpeed = 150.0f;
        particleSize = 9.0f;
        ScreenShake(p->aoeRadius * 0.05f, 0.25f); // Shake based on AoE size
    }

    SpawnParticles(p->position, particleCount, particleColor, Fade(YELLOW, 0.0f), particleSpeed, particleSize, 2.0f, gravity);

    // Record the hit in the history.
    if (primaryTarget && p->hitCount < MAX_CHAIN_HITS) {
        // Ensure we don't double count (safety check)
        bool alreadyCounted = false;
        for (int k = 0; k < p->hitCount; k++) {
            if (primaryTarget->id == p->hitHistory[k]) {
                alreadyCounted = true;
                break;
            }
        }
        if (!alreadyCounted) {
            p->hitHistory[p->hitCount++] = primaryTarget->id;
        }
    }

    // T4 Tesla Chain Logic
    Projectile impact;
    if (p->sourceType == TOWER_T4_TESLA_CHAIN && p->chainCount > 0) {
        impact = *p;
        p = &impact;
        // Find the next target
        int nextTargetId = -1;
        float minDist = 150.0f; // Chain range

        for (int j = 0; j < MAX_ENEMIES; j++) {
            if (!game.enemies[j].active) continue;

            // Check history to prevent ping-pong/looping.
            bool alreadyHit = false;
            for (int k = 0; k < p->hitCount; k++) {
                if (game.enemies[j].id == p->hitHistory[k]) {
                    alreadyHit = true;
                    break;
                }
            }
            if (alreadyHit) continue;

            float dist = Vector2Distance(p->position, game.enemies[j].position);
            if (dist < minDist) {
                minDist = dist;
                nextTargetId = game.enemies[j].id;
            }
        }

        if (nextTargetId != -1) {
            int index = -1;
            for (int k = 0; k < MAX_PROJECTILES; k++) if (!game.projectiles[k].active) { index = k; break; }
            if (index != -1) {
                Projectile* chainP = &game.projectiles[index];
                memcpy(chainP, p, sizeof(Projectile));
                chainP->active = true;
                chainP->position = p->position;

                // find index of next target (we already know j in the loop when we chose nextTargetId)
                int nextIndex = -1;
                for (int j = 0; j < MAX_ENEMIES; j++) {
                    if (game.enemies[j].active && game.enemies[j].id == nextTargetId) { nextIndex = j; break; }
                }
                chainP->targetIndex = nextIndex;
                chainP->targetEnemyId = nextTargetId;

                chainP->damage *= 0.7f;
                chainP->chainCount--;
            }
        }
    }


    // Damage Application
    if (p->aoeRadius > 0) {
        // AoE Damage
        float aoeR2 = p->aoeRadius * p->aoeRadius;
        for (int j = 0; j < MAX_ENEMIES; j++) {
            if (game.enemies[j].active && Vector2DistanceSqr(p->position, game.enemies[j].position) <= aoeR2) {
                // Simple critical hit chance (e.g. 5%)
                bool critical = GetRandomValue(1, 100) <= 5;
                ApplyDamageAndEffects(p, &game.enemies[j], critical);
            }
        }
    } else {
        // Single Target Damage
        // Ensure the primary target is still valid
        if (primaryTarget && primaryTarget->active) {
            bool critical = GetRandomValue(1, 100) <= 5;
            ApplyDamageAndEffects(p, primaryTarget, critical);
        }
    }
}

void ApplyDamageAndEffects(Projectile* p, Enemy* target, bool isCritical) {
    if (!target->active) return;

    // Calculate Damage (RPG Mechanic)
    float actualDamage = CalculateDamage(p->damage, p->damageType, target);

    if (isCritical) {
        actualDamage *= 2.0f; // Double damage on crit
    }

    // Apply float damage
    target->hp -= actualDamage;

    // Floating text feedback
    Color textColor = (p->damageType == DMG_ENERGY) ? COLOR_ENERGY : COLOR_PHYSICAL;
    if (isCritical) textColor = YELLOW;
    // Use formatted text helper
    AddFloatingTextFmt(target->position, textColor, isCritical, "%.0f", actualDamage);

    // Apply Status Effects (RPG Mechanic)
    if (p->applyStatus != STATUS_NONE) {
        bool apply = true;
        float intensity = p->statusIntensity;

        // Random chance effects (Stun)
        if (p->applyStatus == STATUS_STUN) {
            if (GetRandomValue(0, 100) >= (int)p->statusIntensity) {
                apply = false;
            }
            intensity = 1.0f; // Intensity for stun is just 1 (stunned)
        }

        // Synergy effects (Burn applying Melted Armor)
        if (p->applyStatus == STATUS_BURN) {
            // Burn Intensity (DPS) is already set in statusIntensity
            // Also apply Melted Armor (Synergy)
            ApplyStatusEffect(target, STATUS_MELTED_ARMOR, p->statusDuration, 1.15f); // 15% increased physical damage
        }

        if (apply) {
            ApplyStatusEffect(target, p->applyStatus, p->statusDuration, intensity);
        }
    }

    // Check for death
    if (target->hp <= 0) {
        // O(1) index retrieval.
        int targetIndex = (int)(target - game.enemies);
        HandleEnemyDeath(targetIndex, p->sourceTowerIndex);
    }
}


//----------------------------------------------------------------------------------
// Update Implementation (Wave Management)
//----------------------------------------------------------------------------------

void ManageWaves(float dt) {
    if (!game.waveActive) {
        game.waveTimer -= dt;
        if (game.waveTimer <= 0 || (IsKeyPressed(KEY_N) && game.state == GS_PLAYING)) {
            // Start new wave
            game.currentWave++;
            game.waveActive = true;
            // Procedural wave composition (Enhanced)
            game.enemiesToSpawn = 10 + (int)(game.currentWave * 3.5f);
            game.spawnTimer = 1.0f;
            // Use formatted text helper
            AddFloatingTextFmt((Vector2){GAME_AREA_WIDTH/2, 50}, COLOR_ENERGY, true, "WAVE %d INCOMING!", game.currentWave);
            ScreenShake(3.0f, 0.5f);
        }
    } else {
        if (game.enemiesToSpawn > 0) {
            game.spawnTimer -= dt;
            if (game.spawnTimer <= 0) {
                // Determine enemy type based on wave progression (Enhanced logic)
                EnemyType type = ENEMY_BASIC;
                int randVal = GetRandomValue(0, 100);

                // Ensure contiguous ranges.

                // Introduce enemy types gradually and mix them
                if (game.currentWave >= 2 && randVal < 30) type = ENEMY_FAST;

                if (game.currentWave >= 4) {
                    // Introduce Tank
                    if (randVal >= 70 && randVal < 85) type = ENEMY_TANK;
                }

                if (game.currentWave >= 6) {
                    // Introduce Ethereal
                    if (randVal >= 50 && randVal < 65) type = ENEMY_ETHEREAL;
                }

                // Introduce Healers and Spawners
                if (game.currentWave >= 8) {
                    // Introduce Healer
                    if (randVal >= 85 && randVal < 95) type = ENEMY_HEALER;
                }
                 if (game.currentWave >= 10) {
                    // Introduce Spawner
                    if (randVal >= 40 && randVal < 50) type = ENEMY_SPAWNER;
                }

                // Mini-boss waves every 5 waves
                if (game.currentWave % 5 == 0 && game.enemiesToSpawn % 10 == 0) {
                    SpawnEnemy(ENEMY_SPAWNER, game.map.waypoints[0]);
                }

                // Boss waves every 10 waves
                if (game.currentWave % 10 == 0 && game.enemiesToSpawn == 1) {
                    type = ENEMY_BOSS;
                    ScreenShake(10.0f, 1.0f);
                }

                SpawnEnemy(type, game.map.waypoints[0]);
                game.enemiesToSpawn--;
                // Adjust spawn interval
                game.spawnTimer = fmaxf(0.3f, 1.4f - (float)game.currentWave * 0.04f);
            }
        } else {
            // Check if all enemies are dead
            bool enemiesAlive = false;
            for (int i = 0; i < MAX_ENEMIES; i++) {
                if (game.enemies[i].active) {
                    enemiesAlive = true;
                    break;
                }
            }

            if (!enemiesAlive) {
                game.waveActive = false;
                game.waveTimer = WAVE_INTERVAL;
                int bonusGold = 50 + game.currentWave * 20;
                int bonusAether = 5 + game.currentWave / 3; // Aether rewards at the end of the wave
                game.gold += bonusGold;
                game.aether += bonusAether;
                AddFloatingText((Vector2){GAME_AREA_WIDTH/2, 100}, "Wave Complete! Bonus Resources!", COLOR_GOLD, false);
            }
        }
    }
}

//----------------------------------------------------------------------------------
// Drawing Implementation (Main Loop and Map)
//----------------------------------------------------------------------------------

// Helper function for drawing rounded rectangle lines with thickness (compatibility fallback)
void AVDrawRectangleRoundedLinesEx(Rectangle rec, float roundness, int segments, float lineThick, Color color) {
    // Portable fallback: emulate thickness by drawing multiple inset outlines.
    if (lineThick <= 1.0f) {
        DrawRectangleRoundedLines(rec, roundness, segments, color);
        return;
    }

    int steps = (int)floorf(lineThick);
    for (int i = 0; i < steps; i++) {
        Rectangle r = (Rectangle){ rec.x + i, rec.y + i, rec.width - 2*i, rec.height - 2*i };
        if (r.width <= 0 || r.height <= 0) break;
        DrawRectangleRoundedLines(r, roundness, segments, color);
    }
}


void DrawGame(void) {
    BeginDrawing();
    ClearBackground(COLOR_BG);

    if (game.state == GS_TITLE) {
        // Enhanced Title Screen Aesthetics
        DrawText("AETHERIUM VANGUARD", SCREEN_WIDTH/2 - MeasureText("AETHERIUM VANGUARD", 60)/2, SCREEN_HEIGHT/3 - 30, 60, COLOR_ENERGY);
        DrawText("PRESTIGE EDITION", SCREEN_WIDTH/2 - MeasureText("PRESTIGE EDITION", 40)/2, SCREEN_HEIGHT/3 + 40, 40, COLOR_AETHER_RES);

        // Pulsating text
        float alpha = (sinf(game.globalTime * 2.0f) + 1.0f) / 2.0f;
        DrawText("Click or Press ENTER to Start", SCREEN_WIDTH/2 - MeasureText("Click or Press ENTER to Start", 30)/2, SCREEN_HEIGHT/2, 30, Fade(COLOR_TEXT_PRIMARY, alpha));

        DrawText("Controls: WASD (Move), Q (Dash), E (Burst), Space (Attack), 1-4/Click (Build), N (Next Wave), G (Grid)", 20, SCREEN_HEIGHT - 30, 18, COLOR_TEXT_MUTED);
    }
    else {
        // GS_PLAYING, GS_PAUSED, GS_GAME_OVER, GS_LEVEL_UP_HERO

        // Apply Camera Effects (Screen Shake)
        BeginMode2D(game.camera);

        DrawMap();
        DrawEntities();
        DrawVFX();

        EndMode2D();

        DrawUI(); // UI is drawn in screen space (outside BeginMode2D)

        // Overlay States
        if (game.state == GS_PAUSED) {
            DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Fade(BLACK, 0.7f));
            DrawText("PAUSED (Press P)", SCREEN_WIDTH/2 - MeasureText("PAUSED (Press P)", 40)/2, SCREEN_HEIGHT/2 - 20, 40, WHITE);
        }

        if (game.state == GS_LEVEL_UP_HERO) {
            // Draw Hero Level Up Screen (Skill Tree Selection)
            DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Fade(COLOR_BG, 0.85f));
            Rectangle panel = { (float)SCREEN_WIDTH/4, (float)SCREEN_HEIGHT/4, (float)SCREEN_WIDTH/2, (float)SCREEN_HEIGHT/2 };
            DrawRectangleRounded(panel, 0.05f, 16, COLOR_UI_BG);
            AVDrawRectangleRoundedLinesEx(panel, 0.05f, 16, 2.0f, COLOR_AETHER_RES);

            char heroLevelUpTitle[64];
            snprintf(heroLevelUpTitle, sizeof(heroLevelUpTitle), "Select a Skill (Skill Points: %d)", game.hero.skillPoints);
            DrawText("HERO LEVEL UP!", panel.x + 20, panel.y + 20, 30, COLOR_AETHER_RES);
            DrawText(heroLevelUpTitle, panel.x + 20, panel.y + 60, 20, COLOR_TEXT_PRIMARY);

            int startY = (int)panel.y + 100;
            int buttonHeight = 50;
            int spacing = 15;

            const char* skillNames[] = {"Vigor (Attack+)", "Agility (Speed/Dash CD)", "Burst Mastery (AoE+)", "Leadership (Tower XP Aura)"};
            const char* skillDescs[] = {"Increases basic attack damage.", "Increases movement speed and reduces Dash cooldown.", "Increases Aether Burst damage and radius.", "Towers near the hero gain bonus XP."};

            for (int i = 0; i < NUM_HERO_SKILLS; i++) {
                Rectangle btnBounds = {panel.x + 20, (float)startY + i * (buttonHeight + spacing), panel.width - 40, (float)buttonHeight};

                // Use formatted text helper
                char skillLabel[128];
                snprintf(skillLabel, sizeof(skillLabel), "%s (Level %d)", skillNames[i], game.hero.skills[i]);
                if (GuiButton(btnBounds, skillLabel, false, true)) {
                    if (game.hero.skillPoints > 0) {
                        game.hero.skills[i]++;
                        game.hero.skillPoints--;
                        ApplyHeroSkills(); // Re-apply stats immediately
                    }
                }
                SetTooltip(skillNames[i], skillDescs[i], btnBounds);
            }
        }

        if (game.state == GS_GAME_OVER) {
            DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Fade(COLOR_DANGER, 0.3f));
            DrawText("GAME OVER", SCREEN_WIDTH/2 - MeasureText("GAME OVER", 60)/2, SCREEN_HEIGHT/2 - 50, 60, WHITE);
            // Use formatted text helper
            char survived[64];
            snprintf(survived, sizeof(survived), "You survived %d waves.", game.currentWave);
            DrawText(survived, SCREEN_WIDTH/2 - MeasureText(survived, 30)/2, SCREEN_HEIGHT/2 + 20, 30, WHITE);
            DrawText("Press R to Restart", SCREEN_WIDTH/2 - MeasureText("Press R to Restart", 20)/2, SCREEN_HEIGHT/2 + 60, 20, WHITE);
        }

        // Draw tooltip last so it's on top
        if (game.tooltip.visible) {
            DrawTooltip();
        }
    }

    EndDrawing();
}

void DrawMap(void) {
    if (!game.mapRTBuilt) BuildStaticMapRT();

    // Draw the pre-rendered map (RenderTexture is flipped vertically)
    Rectangle src = { 0, 0, (float)game.mapRT.texture.width, -(float)game.mapRT.texture.height };
    Rectangle dst = { 0, 0, GAME_AREA_WIDTH, SCREEN_HEIGHT };
    DrawTexturePro(game.mapRT.texture, src, dst, (Vector2){0,0}, 0.0f, WHITE);

    // Apply day/night tint in a single blended pass
    BeginBlendMode(BLEND_MULTIPLIED);
    DrawRectangle(0, 0, GAME_AREA_WIDTH, SCREEN_HEIGHT, game.environmentColor);
    EndBlendMode();

    // Optional grid overlay (only when requested)
    if (game.showGrid) {
        for (int y = 0; y < MAP_HEIGHT; y++) {
            for (int x = 0; x < MAP_WIDTH; x++) {
                if (game.map.tiles[y][x] == 0) {
                    Rectangle tileRect = {(float)x * TILE_SIZE, (float)y * TILE_SIZE, TILE_SIZE, TILE_SIZE};
                    DrawRectangleLinesEx(tileRect, 1.0f, COLOR_GRID);
                }
            }
        }
    }
}

//----------------------------------------------------------------------------------
// Drawing Implementation (Entities and VFX)
//----------------------------------------------------------------------------------

void DrawEntities(void) {
    DrawEnemies();
    DrawTowers();
    DrawHero();
    DrawProjectiles();
}

void DrawEnemies() {
    for (int i = 0; i < MAX_ENEMIES; i++) {
        if (game.enemies[i].active) {
            Enemy* e = &game.enemies[i];
            Color color;
            float size = 0.0f;
            switch (e->type) {
                case ENEMY_BASIC: color = MAROON; size = 12.0f; break;
                case ENEMY_FAST: color = ORANGE; size = 10.0f; break;
                case ENEMY_TANK: color = DARKBROWN; size = 18.0f; break;
                case ENEMY_ETHEREAL: color = Fade(COLOR_ENERGY, 0.8f); size = 14.0f; break;
                case ENEMY_HEALER: color = LIME; size = 15.0f; break;
                case ENEMY_SPAWNER: color = PURPLE; size = 20.0f; break;
                case ENEMY_MINION: color = DARKGRAY; size = 8.0f; break;
                case ENEMY_BOSS: color = RED; size = 28.0f; break;
            }

            // Apply environment lighting
            color = ColorTint(color, game.environmentColor);

            // Visual indicators for status effects (Detailed Aesthetics)
            bool stunned = false;
            bool burning = false;

            if (e->statusCount > 0) {
                for (int j=0; j<e->statusCount; j++) {
                    switch(e->status[j].type) {
                        case STATUS_SLOW:
                        case STATUS_BRITTLE:
                            color = ColorAlphaBlend(color, COLOR_CRYO, Fade(WHITE, 0.5f));
                            break;
                        case STATUS_BURN:
                            burning = true;
                            break;
                        case STATUS_STUN:
                            stunned = true;
                            break;
                        case STATUS_WEAKEN:
                            // Draw a blue outline (Energy weakness)
                            DrawCircleLines(e->position.x, e->position.y, size + 3, ColorTint(COLOR_ENERGY, game.environmentColor));
                            break;
                        case STATUS_MELTED_ARMOR:
                             // Draw an orange outline (Physical weakness)
                            DrawCircleLines(e->position.x, e->position.y, size + 5, ColorTint(COLOR_PHYSICAL, game.environmentColor));
                            break;
                        default: break;
                    }
                }
            }

            if (burning) {
                // Flicker effect
                if ((int)(game.globalTime * 15) % 2 == 0) color = ColorTint(ORANGE, game.environmentColor);
            }

            if (stunned) {
                color = ColorTint(SKYBLUE, game.environmentColor); // Frozen color
                // Use DrawTextPro for smooth rendering.
                Font font = GetFontDefault();
                Vector2 stunPos = { e->position.x - 20.0f, e->position.y - size - 25.0f };
                DrawTextPro(font, "*STUN*", stunPos, (Vector2){0,0}, 0.0f, 16.0f, 1.0f, YELLOW);
            }

            // Healer Aura Visualization
            if (e->type == ENEMY_HEALER) {
                DrawCircleV(e->position, 100.0f, Fade(LIME, 0.1f));
            }

            // Draw the enemy shape
            if (e->type == ENEMY_HEALER) {
                DrawPoly(e->position, 4, size, 45.0f, color); // Diamond shape
            } else if (e->type == ENEMY_SPAWNER) {
                DrawPoly(e->position, 5, size, 0.0f, color); // Pentagon
            }
            else {
                DrawCircleV(e->position, size, color);
            }


            // Health Bar (Enhanced Aesthetics)
            // Use float HP for calculation
            if (e->maxHp > 0 && e->hp < e->maxHp) {
                float hpPercent = e->hp / e->maxHp;
                hpPercent = Clamp(hpPercent, 0.0f, 1.0f); // Safety clamp

                int barWidth = 40;
                if (size > 20) barWidth = 60;

                Rectangle hpBar = {e->position.x - (float)barWidth/2, e->position.y - size - 10, (float)barWidth, 6};
                DrawRectangleRec(hpBar, COLOR_UI_BG);

                Color hpColor = GREEN;
                if (hpPercent < 0.3f) hpColor = RED;
                else if (hpPercent < 0.6f) hpColor = YELLOW;

                DrawRectangle(hpBar.x, hpBar.y, (int)(hpBar.width * hpPercent), hpBar.height, hpColor);
                DrawRectangleLinesEx(hpBar, 1.0f, BLACK);
            }
        }
    }
}

// Helper function to determine the primary color of a tower
Color GetTowerColor(TowerType type) {
    switch (type) {
        case TOWER_PULSE: case TOWER_T4_PULSE_REPEATER: case TOWER_T4_PULSE_SNIPER: return COLOR_ENERGY;
        case TOWER_CANNON: case TOWER_T4_CANNON_MORTAR: case TOWER_T4_CANNON_VULCAN: return COLOR_PHYSICAL;
        case TOWER_CRYO: case TOWER_T4_CRYO_BLIZZARD: case TOWER_T4_CRYO_FREEZER: return COLOR_CRYO;
        case TOWER_TESLA: case TOWER_T4_TESLA_CHAIN: case TOWER_T4_TESLA_STORM: return COLOR_TESLA;
        default: return GRAY;
    }
}

void DrawTowers() {
    for (int i = 0; i < MAX_TOWERS; i++) {
        if (game.towers[i].active) {
            Tower* t = &game.towers[i];
            Color color = GetTowerColor(t->type);

            // Apply environment lighting
            Color baseColor = ColorTint(ColorBrightness(color, -0.6f), game.environmentColor);
            Color turretColor = ColorTint(color, game.environmentColor);

            // Base (Simple square base)
            DrawRectangle(t->position.x - TILE_SIZE/2 + 4, t->position.y - TILE_SIZE/2 + 4, TILE_SIZE - 8, TILE_SIZE - 8, baseColor);


            // Turret (Rotatable Part) - Detailed visualization based on type
            // Sync beam visualization with aim threshold
            if (t->type == TOWER_CRYO || t->type == TOWER_T4_CRYO_FREEZER) {
                Enemy* target = GetEnemyFromPair(t->targetIndex, t->targetEnemyId);
                if (target) {
                    Vector2 dir = Vector2Subtract(target->position, t->position);
                    float angleToTarget = atan2f(dir.y, dir.x) * RAD2DEG;
                    float angleDiff = fabsf(fmodf(t->rotation - angleToTarget + 180.0f, 360.0f) - 180.0f);
                    float aimTolerance = GetAimToleranceDegrees(t->type);
                    if (angleDiff <= aimTolerance) {
                        float beamWidth = (t->type == TOWER_CRYO) ? 3.0f : 5.0f;
                        DrawLineEx(t->position, target->position, beamWidth, Fade(turretColor, 0.9f));
                        DrawLineEx(t->position, target->position, beamWidth + 6.0f, Fade(turretColor, 0.4f)); // Glow
                    }
                }
                DrawPoly(t->position, 6, 15, t->rotation, turretColor);
            }
            else if (t->type == TOWER_T4_CRYO_BLIZZARD) {
                // Aura visualization (Pulsating field)
                float auraAlpha = 0.1f + (sinf(game.globalTime * 3.0f) + 1.0f) * 0.05f;
                DrawCircleV(t->position, t->stats.range, Fade(turretColor, auraAlpha));
                DrawCircleV(t->position, 18, turretColor);
            }
            else if (t->type == TOWER_TESLA || t->type == TOWER_T4_TESLA_CHAIN || t->type == TOWER_T4_TESLA_STORM) {
                // Tesla visualization (Sphere)
                DrawCircleV(t->position, 14, turretColor);
                // Random arcs (Aesthetic detail)
                if (t->cooldownTimer > 0.1f || GetRandomValue(0, 15) == 0) {
                     float angle = GetRandomValue(0, 360) * DEG2RAD;
                     Vector2 end = Vector2Add(t->position, Vector2Scale((Vector2){cosf(angle), sinf(angle)}, 22));
                     // We use DrawLineEx for simplicity and compatibility.
                     DrawLineEx(t->position, end, 2.0f, Fade(turretColor, 0.8f));
                }
            }
            // Logic for single and dual barrel drawing
            else if (t->type != TOWER_NONE) {
                float length = 28.0f;
                float width = 12.0f;
                Vector2 baseOrigin = { 8, 6 };

                if (t->type == TOWER_T4_PULSE_SNIPER) { length = 40.0f; width = 8.0f; }
                if (t->type == TOWER_CANNON) { length = 22.0f; width = 18.0f; }
                if (t->type == TOWER_T4_CANNON_MORTAR) { length = 25.0f; width = 20.0f; baseOrigin.x = 12.0f; baseOrigin.y = 10.0f; }

                Vector2 origin = baseOrigin;
                origin.x += t->visualRecoil;

                // Compute forward/perpendicular for correct dual-barrel offsets
                float rad = t->rotation * DEG2RAD;
                Vector2 forward = (Vector2){ cosf(rad), sinf(rad) };
                Vector2 perp = (Vector2){ -forward.y, forward.x }; // rotate 90 deg
                float barrelOffset = 4.0f;

                bool dual = (t->type == TOWER_T4_PULSE_REPEATER || t->type == TOWER_T4_CANNON_VULCAN);

                if (dual) {
                    Vector2 pos1 = Vector2Add(t->position, Vector2Scale(perp, barrelOffset));
                    Vector2 pos2 = Vector2Add(t->position, Vector2Scale(perp, -barrelOffset));
                    Rectangle rect1 = (Rectangle){ pos1.x, pos1.y, length, width };
                    Rectangle rect2 = (Rectangle){ pos2.x, pos2.y, length, width };
                    DrawRectanglePro(rect1, origin, t->rotation, turretColor);
                    DrawRectanglePro(rect2, origin, t->rotation, turretColor);
                } else {
                    Rectangle rect = (Rectangle){ t->position.x, t->position.y, length, width };
                    DrawRectanglePro(rect, origin, t->rotation, turretColor);
                }
            }

            // Level indicator (Top left corner of the tile)
            // Use DrawTextPro for smooth rendering.
            char lvlStr[8]; snprintf(lvlStr, sizeof(lvlStr), "L%d", t->stats.level);
            Color levelColor = (t->stats.level >= TOWER_BASE_MAX_LEVEL && t->type < TOWER_T4_PULSE_REPEATER) ? YELLOW : WHITE;
            Font font = GetFontDefault();
            Vector2 lvlPos = { t->position.x - TILE_SIZE/2.0f + 4.0f, t->position.y - TILE_SIZE/2.0f + 4.0f };
            DrawTextPro(font, lvlStr, lvlPos, (Vector2){0,0}, 0.0f, 16.0f, 1.0f, levelColor);
        }
    }
}

void DrawHero() {
    Hero* h = &game.hero;

    // Leadership Aura Visualization
    if (h->skills[SKILL_LEADERSHIP] > 0) {
        float auraRange = 150.0f;
        DrawCircleV(h->position, auraRange, Fade(COLOR_XP, 0.15f));
    }

    // Hero visualization (Circle with outline)
    Color heroColor = ColorTint(COLOR_AETHER_RES, game.environmentColor);
    Color heroOutline = ColorTint(PURPLE, game.environmentColor);
    DrawCircleV(h->position, 15, heroColor);
    DrawCircleLines(h->position.x, h->position.y, 15, heroOutline);
    // Level indicator
    // Use DrawTextPro for smooth rendering.
    char heroLvl[8]; snprintf(heroLvl, sizeof(heroLvl), "H%d", h->level);
    Font font = GetFontDefault();
    Vector2 heroLvlPos = { h->position.x - 10.0f, h->position.y - 8.0f };
    DrawTextPro(font, heroLvl, heroLvlPos, (Vector2){0,0}, 0.0f, 14.0f, 1.0f, WHITE);
}

void DrawProjectiles() {
    for (int i = 0; i < MAX_PROJECTILES; i++) {
        if (game.projectiles[i].active) {
            Projectile* p = &game.projectiles[i];
            Color color = GetTowerColor(p->sourceType);
            // Apply environment tint (less strong for projectiles as they are emissive)
            color = ColorTint(color, game.environmentColor);

            float size = 4.0f;

            switch (p->sourceType) {
                case TOWER_CANNON: size = 8.0f; break;
                case TOWER_T4_CANNON_MORTAR: size = 12.0f; break;
                case TOWER_T4_PULSE_SNIPER: size = 6.0f; break;
                case TOWER_TESLA: case TOWER_T4_TESLA_CHAIN: size = 5.0f; break;
                default: break;
            }

            // Draw Projectile and Glow effect
            DrawCircleV(p->position, size, color);
            if (p->damageType == DMG_ENERGY) {
                DrawCircleV(p->position, size + 5.0f, Fade(color, 0.4f)); // Larger glow for energy
            }
        }
    }
}


void DrawVFX(void) {
    // Draw Particles (using ColorLerp and Size interpolation)
    for (int i = 0; i < MAX_PARTICLES; i++) {
        if (game.particles[i].active) {
            Particle* p = &game.particles[i];
            float progress = p->life / p->maxLife;
            Color color = ColorLerp(p->startColor, p->endColor, progress);
            float size = Lerp(p->startSize, p->endSize, progress);

            // Apply environment tint slightly
            color = ColorTint(color, game.environmentColor);

            DrawCircleV(p->position, size, color);
        }
    }

    // Draw Floating Texts (Drawn in world space)
    for (int i = 0; i < MAX_FLOATING_TEXT; i++) {
        if (game.floatingTexts[i].active) {
            FloatingText* ft = &game.floatingTexts[i];
            // Fade out near the end of lifetime
            float alpha = Clamp(ft->lifetime / 0.5f, 0.0f, 1.0f);
            int fontSize = ft->critical ? 24 : 20;

            // Draw text with outline for better visibility
            Font font = GetFontDefault();
            Vector2 pos = ft->position;
            DrawTextPro(font, ft->text, (Vector2){pos.x + 1.0f, pos.y + 1.0f}, (Vector2){0, 0}, 0.0f, (float)fontSize, 1.0f, Fade(BLACK, alpha));
            DrawTextPro(font, ft->text, pos, (Vector2){0, 0}, 0.0f, (float)fontSize, 1.0f, Fade(ft->color, alpha));
        }
    }
}

//----------------------------------------------------------------------------------
// GUI Drawing Implementation
//----------------------------------------------------------------------------------

void DrawUI(void) {
    // --- 1. Draw In-Game UI Elements (Range Previews) ---

    // Mouse input needs to be adjusted by the camera offset (for screen shake)
    Vector2 mousePosScreen = GetMousePosition();
    Vector2 mousePosWorld = GetScreenToWorld2D(mousePosScreen, game.camera);

    BeginMode2D(game.camera); // Draw range previews in world space

    Vector2 centerPos = {0};
    float range = 0;
    Color color = WHITE;
    bool drawRange = false;

    if (game.placingTower != TOWER_NONE && mousePosScreen.x < GAME_AREA_WIDTH) {
        Vector2 tilePos = WorldToTile(mousePosWorld);
        centerPos = TileToWorldCenter((int)tilePos.x, (int)tilePos.y);

        // Get stats for preview
        Tower temp = {0};
        temp.type = game.placingTower;
        temp.stats.level = 1;
        ConfigureTowerStats(&temp);
        range = temp.stats.range;

        bool canBuild = IsTileBuildable((int)tilePos.x, (int)tilePos.y);
        color = canBuild ? GREEN : RED;
        drawRange = true;

        // Tile highlight
        DrawRectangle(centerPos.x - TILE_SIZE/2, centerPos.y - TILE_SIZE/2, TILE_SIZE, TILE_SIZE, Fade(color, 0.5f));

    } else if (game.selectedTowerIndex != -1) {
        Tower* t = &game.towers[game.selectedTowerIndex];
        centerPos = t->position;
        range = t->stats.range;
        color = YELLOW;
        drawRange = true;
    }

    if (drawRange) {
        if (range > SCREEN_WIDTH * 2) { // Global range visualization
             DrawText("GLOBAL RANGE", centerPos.x - 50, centerPos.y + TILE_SIZE/2 + 5, 20, color);
        } else {
            DrawCircleV(centerPos, range, Fade(color, 0.15f));
            DrawCircleLines(centerPos.x, centerPos.y, range, color);
        }
    }

    EndMode2D();

    // Draw Sidebar (Screen space)
    DrawRectangle(GAME_AREA_WIDTH, 0, UI_WIDTH, SCREEN_HEIGHT, COLOR_UI_BG);
    DrawLine(GAME_AREA_WIDTH, 0, GAME_AREA_WIDTH, SCREEN_HEIGHT, COLOR_UI_ACCENT);

    // Top Info Panel
    DrawText("AETHERIUM VANGUARD", GAME_AREA_WIDTH + 10, 10, 24, COLOR_ENERGY);

    // Use formatted text helper
    char livesStr[32]; snprintf(livesStr, sizeof(livesStr), "LIVES: %d", game.lives);
    DrawText(livesStr, GAME_AREA_WIDTH + 10, 40, 20, game.lives > 5 ? COLOR_TEXT_PRIMARY : COLOR_DANGER);

    char goldStr[32]; snprintf(goldStr, sizeof(goldStr), "GOLD: %d", game.gold);
    DrawText(goldStr, GAME_AREA_WIDTH + 150, 40, 20, COLOR_GOLD);

    char aetherStr[32]; snprintf(aetherStr, sizeof(aetherStr), "AETHER: %d", game.aether);
    DrawText(aetherStr, GAME_AREA_WIDTH + 150, 65, 20, COLOR_AETHER_RES);

    // Wave Info
    if (game.waveActive) {
        char waveStr[64];
        snprintf(waveStr, sizeof(waveStr), "WAVE %d (Remaining: %d)", game.currentWave, game.enemiesToSpawn);
        DrawText(waveStr, GAME_AREA_WIDTH + 10, 95, 20, COLOR_TEXT_PRIMARY);
    } else {
        char nextStr[64];
        snprintf(nextStr, sizeof(nextStr), "Next Wave: %.1fs (N)", game.waveTimer);
        DrawText(nextStr, GAME_AREA_WIDTH + 10, 95, 20, COLOR_TEXT_PRIMARY);
    }

    // Separator Line
    DrawLine(GAME_AREA_WIDTH, 125, SCREEN_WIDTH, 125, COLOR_UI_ACCENT);

    DrawHeroStatus();

    // Separator Line
    DrawLine(GAME_AREA_WIDTH, 260, SCREEN_WIDTH, 260, COLOR_UI_ACCENT);

    if (game.selectedTowerIndex != -1) {
        DrawTowerInspector();
    } else {
        DrawBuildMenu();
    }
}

void DrawHeroStatus() {
    DrawText("HERO STATUS", GAME_AREA_WIDTH + 10, 135, 20, COLOR_AETHER_RES);
    Hero* h = &game.hero;

    char levelStr[32]; snprintf(levelStr, sizeof(levelStr), "Level: %d", h->level);
    DrawText(levelStr, GAME_AREA_WIDTH + 10, 160, 18, COLOR_TEXT_PRIMARY);
    // Use formatted text helper
    char atkStr[64]; snprintf(atkStr, sizeof(atkStr), "Attack: %d (Phys)", h->attackDamage);
    DrawText(atkStr, GAME_AREA_WIDTH + 130, 160, 18, COLOR_TEXT_PRIMARY);

    if (h->skillPoints > 0) {
         DrawText("SKILL POINT AVAILABLE!", GAME_AREA_WIDTH + 10, 180, 18, YELLOW);
    }

    // XP Bar
    Rectangle xpBar = {GAME_AREA_WIDTH + 10, 200, UI_WIDTH - 20, 20};
    float xpPercent = 0.0f;
    if (h->xpToNextLevel > 0) {
        xpPercent = (float)h->xp / h->xpToNextLevel;
    }
    DrawRectangleRec(xpBar, COLOR_UI_ACCENT);
    DrawRectangle(xpBar.x, xpBar.y, (int)(xpBar.width * xpPercent), xpBar.height, COLOR_AETHER_RES);
    DrawRectangleLinesEx(xpBar, 1, BLACK);
    // Use formatted text helper
    char xpStr[64]; snprintf(xpStr, sizeof(xpStr), "XP: %d / %d", h->xp, h->xpToNextLevel);
    DrawText(xpStr, xpBar.x + 10, xpBar.y + 2, 16, COLOR_TEXT_PRIMARY);

    // Ability Cooldowns
    // Dash (Q)
    Rectangle cdBarQ = {GAME_AREA_WIDTH + 10, 230, (UI_WIDTH - 30)/2, 20};
    float cdPercentQ = 1.0f;
    if (h->dashCooldown > 0) {
        cdPercentQ = 1.0f - Clamp(h->currentDashCooldown / h->dashCooldown, 0.0f, 1.0f);
    }
    DrawRectangleRec(cdBarQ, COLOR_UI_ACCENT);
    DrawRectangle(cdBarQ.x, cdBarQ.y, (int)(cdBarQ.width * cdPercentQ), cdBarQ.height, COLOR_AETHER_RES);
    DrawText("Dash (Q)", cdBarQ.x + 5, cdBarQ.y + 3, 14, COLOR_TEXT_PRIMARY);
    SetTooltip("Dash (Q)", "Rapid movement burst.", cdBarQ);

    // Burst (E)
    Rectangle cdBarE = {GAME_AREA_WIDTH + 20 + (UI_WIDTH - 30)/2, 230, (UI_WIDTH - 30)/2, 20};
    float cdPercentE = 1.0f;
    if (h->burstCooldown > 0) {
        cdPercentE = 1.0f - Clamp(h->currentBurstCooldown / h->burstCooldown, 0.0f, 1.0f);
    }
    DrawRectangleRec(cdBarE, COLOR_UI_ACCENT);
    DrawRectangle(cdBarE.x, cdBarE.y, (int)(cdBarE.width * cdPercentE), cdBarE.height, COLOR_ENERGY);
    DrawText("Burst (E)", cdBarE.x + 5, cdBarE.y + 3, 14, COLOR_TEXT_PRIMARY);
    SetTooltip("Aether Burst (E)", "AoE damage and energy weakness debuff.", cdBarE);
}


void DrawBuildMenu() {
    DrawText("BUILD MENU (1-4)", GAME_AREA_WIDTH + 10, 270, 20, COLOR_ENERGY);

    int startY = 300;
    int buttonHeight = 65;
    int spacing = 15;

    TowerType types[] = {TOWER_PULSE, TOWER_CANNON, TOWER_CRYO, TOWER_TESLA};

    for (int i = 0; i < 4; i++) {
        Rectangle btnBounds = {GAME_AREA_WIDTH + 10, (float)startY + i * (buttonHeight + spacing), UI_WIDTH - 20, (float)buttonHeight};
        int cost = GetTowerCost(types[i]);
        bool canAfford = game.gold >= cost;
        bool selected = game.placingTower == types[i];

        const char* name = GetTowerName(types[i]);
        const char* desc = GetTowerDescription(types[i]);

        // Use formatted text helper
        char label[128];
        snprintf(label, sizeof(label), "%s (%dG)", name, cost);
        if (GuiButton(btnBounds, label, selected, canAfford)) {
            if (canAfford) {
                game.placingTower = types[i];
                game.selectedTowerIndex = -1;
            } else {
                AddFloatingText((Vector2){GAME_AREA_WIDTH + 50, btnBounds.y}, "Not enough Gold!", COLOR_DANGER, false);
            }
        }
        SetTooltip(name, desc, btnBounds);
    }
}

void DrawTowerInspector() {
    if (game.selectedTowerIndex == -1 || !game.towers[game.selectedTowerIndex].active) {
        game.selectedTowerIndex = -1;
        return;
    }

    Tower* t = &game.towers[game.selectedTowerIndex];

    DrawText("TOWER INSPECTION", GAME_AREA_WIDTH + 10, 270, 20, YELLOW);

    // Use formatted text helper
    char titleStr[128]; snprintf(titleStr, sizeof(titleStr), "%s (L%d)", GetTowerName(t->type), t->stats.level);
    DrawText(titleStr, GAME_AREA_WIDTH + 10, 300, 22, GetTowerColor(t->type));

    char killsStr[32]; snprintf(killsStr, sizeof(killsStr), "Kills: %d", t->kills);
    DrawText(killsStr, GAME_AREA_WIDTH + 200, 305, 18, COLOR_TEXT_PRIMARY);

    // Tower XP Bar
    int currentY = 340;

    // Check if the tower is a base tower (eligible for XP gain and leveling)
    if (t->type >= TOWER_PULSE && t->type <= TOWER_TESLA) {
        DrawText("Experience:", GAME_AREA_WIDTH + 10, currentY, 18, COLOR_XP);
        currentY += 20;
        Rectangle xpBar = {GAME_AREA_WIDTH + 10, (float)currentY, UI_WIDTH - 20, 20};

        if (t->stats.level < TOWER_BASE_MAX_LEVEL) {
            float xpPercent = 0.0f;
            if (t->stats.xpToNextLevel > 0) {
                xpPercent = (float)t->stats.xp / t->stats.xpToNextLevel;
            }
            DrawRectangleRec(xpBar, COLOR_UI_ACCENT);
            DrawRectangle(xpBar.x, xpBar.y, (int)(xpBar.width * xpPercent), xpBar.height, COLOR_XP);
            DrawRectangleLinesEx(xpBar, 1, BLACK);
            // Use formatted text helper
            char txp[64]; snprintf(txp, sizeof(txp), "%d / %d", t->stats.xp, t->stats.xpToNextLevel);
            DrawText(txp, xpBar.x + 10, xpBar.y + 2, 16, COLOR_TEXT_PRIMARY);
        } else {
            // MAX LEVEL - Ready for Upgrade
            DrawRectangleRec(xpBar, COLOR_XP);
            DrawText("MAX LEVEL - READY FOR UPGRADE", xpBar.x + 10, xpBar.y + 2, 16, BLACK);
        }
        currentY += 30;
    } else {
        // T4 Towers are already maxed out.
        DrawText("Specialized Tower (Max Tier)", GAME_AREA_WIDTH + 10, currentY, 18, COLOR_XP);
        currentY += 30;
    }


    // Stats
    currentY += 10;
    DrawText("Stats:", GAME_AREA_WIDTH + 10, currentY, 20, YELLOW);
    currentY += 25;

    const char* dmgType = t->damageType == DMG_ENERGY ? "Energy" : (t->damageType == DMG_PHYSICAL ? "Physical" : "True");
    Color statColor = GetTowerColor(t->type);

    // Use formatted text helper
    char dmgStr[64];
    snprintf(dmgStr, sizeof(dmgStr), "Damage: %.1f (%s)", t->stats.damage, dmgType);
    DrawText(dmgStr, GAME_AREA_WIDTH + 10, currentY, 18, statColor);
    currentY += 25;

    // Use formatted text helper
    const char* rangeText = (t->stats.range > SCREEN_WIDTH * 2) ? "Global" : NULL;
    char rangeBuf[32];
    if (!rangeText) { snprintf(rangeBuf, sizeof(rangeBuf), "%.0f", t->stats.range); rangeText = rangeBuf; }
    char rangeStr[64]; snprintf(rangeStr, sizeof(rangeStr), "Range: %s", rangeText);
    DrawText(rangeStr, GAME_AREA_WIDTH + 10, currentY, 18, COLOR_TEXT_PRIMARY);
    currentY += 25;

    if (t->type == TOWER_CRYO || t->type == TOWER_T4_CRYO_FREEZER) {
        DrawText("Fire Rate: Continuous (DPS)", GAME_AREA_WIDTH + 10, currentY, 18, COLOR_TEXT_PRIMARY);
    } else if (t->type == TOWER_T4_CRYO_BLIZZARD) {
        // Use formatted text helper
        char slowStr[64]; snprintf(slowStr, sizeof(slowStr), "Slow Aura: %.0f%%", t->stats.fireRate * 100.0f);
        DrawText(slowStr, GAME_AREA_WIDTH + 10, currentY, 18, COLOR_TEXT_PRIMARY);
    }
    else {
        // Use formatted text helper
        char rateStr[64]; snprintf(rateStr, sizeof(rateStr), "Fire Rate: %.2f/s", t->stats.fireRate);
        DrawText(rateStr, GAME_AREA_WIDTH + 10, currentY, 18, COLOR_TEXT_PRIMARY);
    }
    currentY += 35;

    // Targeting Mode Selection
    DrawLine(GAME_AREA_WIDTH, currentY, SCREEN_WIDTH, currentY, COLOR_UI_ACCENT);
    currentY += 10;

    // Check if tower uses targeting (e.g., Blizzard doesn't)
    if (t->type != TOWER_T4_CRYO_BLIZZARD) {
        DrawText("Targeting Mode:", GAME_AREA_WIDTH + 10, currentY, 20, YELLOW);
        currentY += 25;
        Rectangle btnTarget = {GAME_AREA_WIDTH + 10, (float)currentY, UI_WIDTH - 20, 40};
        const char* modeText = "Unknown";
        switch (t->targetingMode) {
            case TARGET_FIRST: modeText = "First (Default)"; break;
            case TARGET_CLOSEST: modeText = "Closest"; break;
            case TARGET_STRONGEST: modeText = "Strongest (HP)"; break;
            case TARGET_WEAKEST: modeText = "Weakest (HP)"; break;
        }

        if (GuiButton(btnTarget, modeText, false, true)) {
            // Cycle through targeting modes
            t->targetingMode = (t->targetingMode + 1) % NUM_TARGETING_MODES;
        }
        SetTooltip("Targeting Mode", "Change how the tower prioritizes enemies.", btnTarget);
        currentY += 50;
    }

    // Upgrade Paths
    // DrawLine(GAME_AREA_WIDTH, currentY, SCREEN_WIDTH, currentY, COLOR_UI_ACCENT);
    // currentY += 10;

    if (t->stats.level >= TOWER_BASE_MAX_LEVEL && t->type >= TOWER_PULSE && t->type <= TOWER_TESLA) {
        DrawTowerUpgradePaths(t);
    }

    // Sell Button
    Rectangle btnSell = {GAME_AREA_WIDTH + 10, SCREEN_HEIGHT - 50, UI_WIDTH - 20, 40};
    // Sell value based on 60% of the tracked total cost.
    int sellValue = (int)(t->totalCost * 0.6f);
    // Use formatted text helper
    char sellLabel[64]; snprintf(sellLabel, sizeof(sellLabel), "Sell Tower (%dG)", sellValue);
    if (GuiButton(btnSell, sellLabel, false, true)) {
        SellTower(game.selectedTowerIndex);
    }
    SetTooltip("Sell", "Sell the tower for a partial refund.", btnSell);
}

// Draws the T4 specialization options
void DrawTowerUpgradePaths(Tower* t) {
    DrawText("T4 UPGRADE PATHS (Requires Aether)", GAME_AREA_WIDTH + 10, 600, 20, COLOR_AETHER_RES);

    TowerType path1 = TOWER_NONE;
    TowerType path2 = TOWER_NONE;

    switch (t->type) {
        case TOWER_PULSE: path1 = TOWER_T4_PULSE_REPEATER; path2 = TOWER_T4_PULSE_SNIPER; break;
        case TOWER_CANNON: path1 = TOWER_T4_CANNON_MORTAR; path2 = TOWER_T4_CANNON_VULCAN; break;
        case TOWER_CRYO: path1 = TOWER_T4_CRYO_BLIZZARD; path2 = TOWER_T4_CRYO_FREEZER; break;
        case TOWER_TESLA: path1 = TOWER_T4_TESLA_CHAIN; path2 = TOWER_T4_TESLA_STORM; break;
        default: return;
    }

    int startY = 630;
    int buttonHeight = 50;

    TowerType paths[] = {path1, path2};

    for (int i = 0; i < 2; i++) {
        Rectangle btnBounds = {GAME_AREA_WIDTH + 10, (float)startY + i * (buttonHeight + 15), UI_WIDTH - 20, (float)buttonHeight};
        int costGold = GetTowerCost(paths[i]);
        int costAether = GetTowerAetherCost(paths[i]);

        bool canAfford = (game.gold >= costGold) && (game.aether >= costAether);
        const char* name = GetTowerName(paths[i]);
        const char* desc = GetTowerDescription(paths[i]);

        // Use formatted text helper
        char upLabel[128];
        snprintf(upLabel, sizeof(upLabel), "%s (%dG, %dA)", name, costGold, costAether);
        if (GuiButton(btnBounds, upLabel, false, canAfford)) {
            if (canAfford) {
                game.gold -= costGold;
                game.aether -= costAether;
                if (UpgradeTower(t, paths[i])) {
                    // Update total cost upon successful upgrade.
                    t->totalCost += costGold;
                    // Success feedback
                    AddFloatingText(t->position, "UPGRADED!", COLOR_AETHER_RES, true);
                    ScreenShake(3.0f, 0.3f);
                }
            } else {
                // Error feedback
                AddFloatingText((Vector2){GAME_AREA_WIDTH + 50, btnBounds.y}, "Cannot Afford!", COLOR_DANGER, false);
            }
        }
        SetTooltip(name, desc, btnBounds);
    }
}

// Draw the dynamic tooltip
void DrawTooltip() {
    if (game.tooltip.visible) {
        Vector2 mousePos = GetMousePosition();
        int padding = 10;
        int titleSize = 20;
        int textSize = 16;
        int maxWidth = 300;

        // Calculate approximate height based on lines (assuming manual line breaks '\n')
        int lines = 1;
        for (const char* p = game.tooltip.description; *p; p++) {
            if (*p == '\n') lines++;
        }

        int textHeight = lines * (textSize + 5);
        int titleHeight = titleSize + 5;

        int width = MeasureText(game.tooltip.title, titleSize);
        // Approximate width calculation for description
        int descWidth = MeasureText(game.tooltip.description, textSize);
        if (descWidth > width) width = descWidth;

        if (width > maxWidth) width = maxWidth;

        Rectangle tooltipRect = {
            mousePos.x + 15, // Offset from cursor
            mousePos.y + 15,
            (float)width + padding * 2,
            (float)titleHeight + textHeight + padding * 3
        };

        // Adjust position if it goes off-screen
        if (tooltipRect.x + tooltipRect.width > SCREEN_WIDTH) {
            tooltipRect.x = SCREEN_WIDTH - tooltipRect.width - 5;
        }
        if (tooltipRect.y + tooltipRect.height > SCREEN_HEIGHT) {
            tooltipRect.y = mousePos.y - tooltipRect.height - 15;
        }

        // Draw background and border
        DrawRectangleRec(tooltipRect, Fade(COLOR_BG, 0.9f));
        DrawRectangleLinesEx(tooltipRect, 1.0f, COLOR_UI_ACCENT);

        // Draw content
        DrawText(game.tooltip.title, tooltipRect.x + padding, tooltipRect.y + padding, titleSize, COLOR_ENERGY);
        DrawLine(tooltipRect.x + padding, tooltipRect.y + padding + titleHeight + 5, tooltipRect.x + width + padding, tooltipRect.y + padding + titleHeight + 5, COLOR_UI_ACCENT);
        // Standard DrawText handles '\n' for line breaks.
        DrawText(game.tooltip.description, tooltipRect.x + padding, tooltipRect.y + padding * 2 + titleHeight, textSize, COLOR_TEXT_PRIMARY);
    }
}

//----------------------------------------------------------------------------------
// Game Logic Helpers Implementation (Spawning and Setup)
//----------------------------------------------------------------------------------

// Updated SpawnEnemy to take a position argument (for minions)
void SpawnEnemy(EnemyType type, Vector2 position) {
    int index = -1;
    for (int i = 0; i < MAX_ENEMIES; i++) {
        if (!game.enemies[i].active) {
            index = i;
            break;
        }
    }

    if (index != -1) {
        Enemy* e = &game.enemies[index];
        memset(e, 0, sizeof(Enemy));
        e->active = true;
        e->id = game.enemyIdCounter++;
        e->type = type;
        e->position = position;

         // Determine starting waypoint index.
        if (Vector2DistanceSqr(position, game.map.waypoints[0]) < 1.0f) {
            // Spawned at the start of the map.
             e->waypointIndex = 1;
        } else {
            // Minion pathfinding on spawn.
            // Minions spawned mid-map must find the closest path segment they are on, not just the closest node.

            float minDistSqr = 10000000.0f; // Initialize with a large value
            int bestIndex = 1; // The index of the waypoint at the END of the best segment.

            // Iterate over all path segments (WP[i-1] to WP[i])
            for (int i = 1; i < game.map.waypointCount; i++) {
                Vector2 segmentStart = game.map.waypoints[i-1];
                Vector2 segmentEnd = game.map.waypoints[i];

                // Find the closest point on this segment to the spawn position
                Vector2 closestPoint = ClosestPointOnSegment(position, segmentStart, segmentEnd);

                float distSqr = Vector2DistanceSqr(position, closestPoint);

                if (distSqr < minDistSqr) {
                    minDistSqr = distSqr;
                    bestIndex = i;
                }
            }
            // Target the waypoint at the end of the closest segment.
            e->waypointIndex = bestIndex;
        }


        // Define stats and apply wave scaling (Enhanced RPG Difficulty Scaling)
        // Ensure HP calculations are float.
        float hpMult = 1.0f + (game.currentWave - 1) * 0.18f + powf((float)game.currentWave, 1.1f) * 0.01f;
        float armorMult = 1.0f + (game.currentWave - 1) * 0.1f;

        switch (type) {
            case ENEMY_BASIC:
                e->maxHp = 100.0f * hpMult;
                e->baseSpeed = 80.0f;
                e->armor = 10 * armorMult;
                e->energyResist = 10 * armorMult;
                e->goldValue = 10;
                e->aetherValue = (GetRandomValue(0, 100) < 5) ? 1 : 0; // 5% chance for Aether
                e->xpValue = 20;
                break;
            case ENEMY_FAST:
                e->maxHp = 75.0f * hpMult;
                e->baseSpeed = 170.0f;
                e->armor = 5 * armorMult;
                e->energyResist = 15 * armorMult;
                e->goldValue = 15;
                e->aetherValue = (GetRandomValue(0, 100) < 8) ? 1 : 0;
                e->xpValue = 25;
                break;
            case ENEMY_TANK:
                e->maxHp = 600.0f * hpMult;
                e->baseSpeed = 50.0f;
                e->armor = 70 * armorMult; // High physical
                e->energyResist = 20 * armorMult;
                e->goldValue = 30;
                e->aetherValue = (GetRandomValue(0, 100) < 15) ? 2 : 0;
                e->xpValue = 50;
                break;
            case ENEMY_ETHEREAL:
                e->maxHp = 250.0f * hpMult;
                e->baseSpeed = 70.0f;
                e->armor = 10 * armorMult;
                e->energyResist = 70 * armorMult; // High energy
                e->goldValue = 35;
                e->aetherValue = (GetRandomValue(0, 100) < 15) ? 2 : 0;
                e->xpValue = 55;
                break;
            case ENEMY_HEALER:
                e->maxHp = 300.0f * hpMult;
                e->baseSpeed = 65.0f;
                e->armor = 30 * armorMult;
                e->energyResist = 30 * armorMult;
                e->goldValue = 40;
                e->aetherValue = (GetRandomValue(0, 100) < 20) ? 3 : 1;
                e->xpValue = 60;
                break;
            case ENEMY_SPAWNER:
                e->maxHp = 1500.0f * hpMult;
                e->baseSpeed = 60.0f;
                e->armor = 50 * armorMult;
                e->energyResist = 50 * armorMult;
                e->goldValue = 150;
                e->aetherValue = 10;
                e->xpValue = 250;
                break;
            case ENEMY_MINION: // Weaker scaling
                 e->maxHp = 50.0f * (1.0f + (game.currentWave - 1) * 0.1f);
                e->baseSpeed = 90.0f;
                e->armor = 5;
                e->energyResist = 5;
                e->goldValue = 3;
                e->aetherValue = 0;
                e->xpValue = 5;
                break;
            case ENEMY_BOSS:
                e->maxHp = 5000.0f * hpMult;
                e->baseSpeed = 60.0f;
                e->armor = 60 * armorMult;
                e->energyResist = 60 * armorMult;
                e->goldValue = 500;
                e->aetherValue = 50;
                e->xpValue = 1000;
                break;
        }
        e->hp = e->maxHp;
        e->speed = e->baseSpeed;
    }
}

//----------------------------------------------------------------------------------
// Game Logic Helpers Implementation (Towers and Projectiles)
//----------------------------------------------------------------------------------

void FireProjectile(Tower* tower, Enemy* target) {
    int index = -1;
    for (int i = 0; i < MAX_PROJECTILES; i++) { if (!game.projectiles[i].active) { index = i; break; } }
    if (index == -1) return;

    Projectile* p = &game.projectiles[index];
    memset(p, 0, sizeof(Projectile));
    p->active = true;
    p->position = tower->position;
    p->damage = tower->stats.damage;
    p->damageType = tower->damageType;
    p->sourceType = tower->type;
    p->sourceTowerIndex = (int)(tower - game.towers);

    int tIndex = (int)(target - game.enemies);
    p->targetIndex = tIndex;
    p->targetEnemyId = target->id;
    p->targetPosition = target->position;


    // Configure projectile behavior based on Tower Type
    switch (tower->type) {
         // PULSE Variants
        case TOWER_PULSE: case TOWER_T4_PULSE_REPEATER:
            p->speed = 650.0f;
            break;
        case TOWER_T4_PULSE_SNIPER:
            p->speed = 1200.0f;
            break;

        // CANNON Variants (Apply Burn/Melted Armor Synergy)
        case TOWER_CANNON: case TOWER_T4_CANNON_VULCAN: case TOWER_T4_CANNON_MORTAR:
            p->speed = (tower->type == TOWER_CANNON) ? 350.0f : (tower->type == TOWER_T4_CANNON_VULCAN ? 700.0f : 250.0f);
            if (tower->type == TOWER_CANNON) p->aoeRadius = 50.0f + tower->stats.level * 10.0f;
            if (tower->type == TOWER_T4_CANNON_MORTAR) {
                p->aoeRadius = 150.0f;

                // Implement predictive targeting for Mortar.
                // P_future = P_current + V_target * T_flight

                // 1. Estimate Target Velocity Vector (based on direction to next waypoint)
                // We use baseSpeed for prediction as current speed might be affected by slows.
                if (target->baseSpeed > 0 && target->waypointIndex < game.map.waypointCount) {
                    Vector2 nextWaypoint = game.map.waypoints[target->waypointIndex];

                    // Check distance to avoid normalization issues if the target is very close to the waypoint
                    if (Vector2DistanceSqr(target->position, nextWaypoint) > 1.0f) {
                        Vector2 direction = Vector2Normalize(Vector2Subtract(nextWaypoint, target->position));
                        Vector2 targetVelocity = Vector2Scale(direction, target->baseSpeed);

                        // 2. Estimate time of flight (T_flight = Distance / Speed_projectile)
                        float distance = Vector2Distance(p->position, target->position);
                        if (p->speed > 0) {
                            float estimatedTime = distance / p->speed;

                            // 3. Calculate the predicted position
                            Vector2 predictedPos = Vector2Add(target->position, Vector2Scale(targetVelocity, estimatedTime));
                            p->targetPosition = predictedPos;
                        }
                    }
                }
                // If stationary or at the end of the path, p->targetPosition remains target->position.
            }

            p->applyStatus = STATUS_BURN;
            p->statusDuration = 5.0f;
            p->statusIntensity = 10.0f + tower->stats.level * 5.0f; // Burn DPS
            break;

        // TESLA Variants
        case TOWER_TESLA: case TOWER_T4_TESLA_STORM:
            p->speed = 900.0f;
            p->applyStatus = STATUS_STUN;
            p->statusDuration = 0.6f;
            p->statusIntensity = 20.0f + tower->stats.level * 7.0f; // Stun chance %
            break;
        case TOWER_T4_TESLA_CHAIN:
            p->speed = 900.0f;
            p->chainCount = 3 + tower->stats.level;
            break;

        // CRYO Variants (Should not fire projectiles)
        default:
            p->active = false;
            return;
    }
}

bool PlaceTower(int x, int y, TowerType type) {
    if (!IsTileBuildable(x, y)) {
        AddFloatingText(TileToWorldCenter(x,y), "Cannot build here!", COLOR_DANGER, false);
        return false;
    }

    int cost = GetTowerCost(type);
    if (game.gold < cost) {
        AddFloatingText(TileToWorldCenter(x,y), "Not enough gold!", COLOR_DANGER, false);
        return false;
    }

    int index = -1;
    for (int i = 0; i < MAX_TOWERS; i++) {
        if (!game.towers[i].active) { index = i; break; }
    }

    if (index != -1) {
        game.gold -= cost;
        Tower* t = &game.towers[index];
        memset(t, 0, sizeof(Tower));
        t->active = true;
        t->type = type;
        t->position = TileToWorldCenter(x, y);

        Vector2 tp = WorldToTile(t->position);
        int tx = (int)tp.x, ty = (int)tp.y;
        if (tx >= 0 && tx < MAP_WIDTH && ty >= 0 && ty < MAP_HEIGHT) {
            game.occupied[ty][tx] = true;
        }
        t->targetIndex = -1; // init O(1) target
        t->targetEnemyId = -1;

        t->stats.level = 1;
        t->targetingMode = TARGET_FIRST;
        // Initialize total cost
        t->totalCost = cost;
        ConfigureTowerStats(t);
        SpawnParticles(t->position, 40, COLOR_ENERGY, Fade(COLOR_ENERGY, 0.0f), 80.0f, 8.0f, 2.0f, false);
        return true;
    }
    return false;
}

void SellTower(int towerIndex) {
     if (towerIndex < 0 || towerIndex >= MAX_TOWERS || !game.towers[towerIndex].active) return;

    Tower* t = &game.towers[towerIndex];
    // Sell value (60% of tracked total cost)
    int sellValue = (int)(t->totalCost * 0.6f);
    game.gold += sellValue;

    Vector2 tp = WorldToTile(t->position);
    int tx = (int)tp.x, ty = (int)tp.y;
    if (tx >= 0 && tx < MAP_WIDTH && ty >= 0 && ty < MAP_HEIGHT) {
        game.occupied[ty][tx] = false;
    }

    // Use formatted text helper
    AddFloatingTextFmt(t->position, COLOR_GOLD, false, "SOLD +%dG", sellValue);
    SpawnParticles(t->position, 30, GRAY, Fade(GRAY, 0.0f), 80.0f, 8.0f, 2.0f, true);

    t->active = false;
    game.selectedTowerIndex = -1;
}

bool UpgradeTower(Tower* t, TowerType newType) {
    if (!t || !t->active) return false;

    // Validation (ensure the upgrade path is correct)
    bool valid = false;
     switch (t->type) {
        case TOWER_PULSE: if (newType == TOWER_T4_PULSE_REPEATER || newType == TOWER_T4_PULSE_SNIPER) valid = true; break;
        case TOWER_CANNON: if (newType == TOWER_T4_CANNON_MORTAR || newType == TOWER_T4_CANNON_VULCAN) valid = true; break;
        case TOWER_CRYO: if (newType == TOWER_T4_CRYO_BLIZZARD || newType == TOWER_T4_CRYO_FREEZER) valid = true; break;
        case TOWER_TESLA: if (newType == TOWER_T4_TESLA_CHAIN || newType == TOWER_T4_TESLA_STORM) valid = true; break;
        default: break;
    }

    if (valid) {
        t->type = newType;
        // Recalculate stats
        ConfigureTowerStats(t);
        SpawnParticles(t->position, 100, COLOR_AETHER_RES, Fade(YELLOW, 0.0f), 150.0f, 10.0f, 3.0f, false);
        return true;
    }
    return false;
}

void ConfigureTowerStats(Tower* tower) {
    TowerStats* s = &tower->stats;

    // Calculate XP requirement (Only for base towers)
    if (tower->type >= TOWER_PULSE && tower->type <= TOWER_TESLA && s->level < TOWER_BASE_MAX_LEVEL) {
        int effectiveLevel = (s->level > 0) ? s->level : 1;
        s->xpToNextLevel = (int)(150 * pow(1.9, effectiveLevel - 1));
    } else {
        s->xpToNextLevel = 99999; // Max level indicator
    }

    // Base stats definition (Extensive list covering all Tiers)
    switch (tower->type) {
        // --- BASE TOWERS (Tier 1-3) ---
        case TOWER_PULSE:
            s->damage = 20; s->range = 150.0f; s->fireRate = 2.5f;
            tower->damageType = DMG_ENERGY;
            break;
        case TOWER_CANNON:
            s->damage = 80; s->range = 130.0f; s->fireRate = 0.5f;
            tower->damageType = DMG_PHYSICAL;
            break;
        case TOWER_CRYO:
            s->damage = 20; s->range = 140.0f; s->fireRate = 0.0f; // DPS
            tower->damageType = DMG_ENERGY;
            break;
        case TOWER_TESLA:
            s->damage = 50; s->range = 180.0f; s->fireRate = 1.1f;
            tower->damageType = DMG_ENERGY;
            break;

        // --- TIER 4 SPECIALIZATIONS ---
        // PULSE T4
        case TOWER_T4_PULSE_REPEATER:
            s->damage = 25; s->range = 160.0f; s->fireRate = 8.0f;
            tower->damageType = DMG_ENERGY;
            break;
        case TOWER_T4_PULSE_SNIPER:
            s->damage = 300; s->range = 400.0f; s->fireRate = 0.8f;
            tower->damageType = DMG_ENERGY;
            break;

        // CANNON T4
        case TOWER_T4_CANNON_MORTAR:
            s->damage = 500; s->range = 9999.0f; s->fireRate = 0.3f; // Global
            tower->damageType = DMG_PHYSICAL;
            break;
        case TOWER_T4_CANNON_VULCAN:
            s->damage = 30; s->range = 140.0f; s->fireRate = 10.0f;
            tower->damageType = DMG_PHYSICAL;
            break;

        // CRYO T4
        case TOWER_T4_CRYO_BLIZZARD:
            s->damage = 10; s->range = 120.0f; s->fireRate = 0.75f; // DPS, Range, Slow Intensity
            tower->damageType = DMG_ENERGY;
            break;
        case TOWER_T4_CRYO_FREEZER:
            s->damage = 50; s->range = 150.0f; s->fireRate = 1.5f; // DPS, Range, Freeze Duration
            tower->damageType = DMG_ENERGY;
            break;

        // TESLA T4
        case TOWER_T4_TESLA_CHAIN:
            s->damage = 80; s->range = 200.0f; s->fireRate = 1.5f;
            tower->damageType = DMG_ENERGY;
            break;
        case TOWER_T4_TESLA_STORM:
            s->damage = 200; s->range = 220.0f; s->fireRate = 0.9f;
            tower->damageType = DMG_ENERGY;
            break;

        default:
            return;
    }

    // Apply level scaling (Generalized)
    int scalingLevel = (s->level > 0) ? s->level : 1;

    // Scaling is now applied universally based on the tower's level.

    float damageMult = 1.0f + (scalingLevel - 1) * 0.35f;
    float rangeMult = 1.0f + (scalingLevel - 1) * 0.10f;
    float rateMult = 1.0f + (scalingLevel - 1) * 0.15f;

    s->damage *= damageMult;
    s->range *= rangeMult;

    // Apply fire rate scaling only if applicable (Not beams/auras)
    if (tower->type != TOWER_CRYO && tower->type != TOWER_T4_CRYO_BLIZZARD && tower->type != TOWER_T4_CRYO_FREEZER) {
        s->fireRate *= rateMult;
    }
}

//----------------------------------------------------------------------------------
// RPG Systems Implementation (XP, Leveling, Combat Mechanics)
//----------------------------------------------------------------------------------

void GrantXP(int towerIndex, int xp) {
     if (towerIndex < 0 || towerIndex >= MAX_TOWERS || !game.towers[towerIndex].active) return;

    Tower* t = &game.towers[towerIndex];

    // T4 Towers cannot gain XP
    if (t->type < TOWER_PULSE || t->type > TOWER_TESLA) return;

    // Apply Hero Leadership bonus
    if (game.hero.skills[SKILL_LEADERSHIP] > 0) {
        float leadershipRange = 150.0f;
        if (Vector2Distance(t->position, game.hero.position) <= leadershipRange) {
            float bonusXP = xp * (game.hero.skills[SKILL_LEADERSHIP] * 0.15f); // 15% bonus XP per level
            xp += (int)bonusXP;
        }
    }

    t->stats.xp += xp;
    AddFloatingTextFmt(t->position, COLOR_XP, false, "+%d XP", xp);

    // Check for level up
    while (t->stats.xp >= t->stats.xpToNextLevel && t->stats.level < TOWER_BASE_MAX_LEVEL) {
        LevelUpTower(towerIndex);
    }
}

void LevelUpTower(int towerIndex) {
    Tower* t = &game.towers[towerIndex];
    t->stats.xp -= t->stats.xpToNextLevel;
    t->stats.level++;
    ConfigureTowerStats(t);
    AddFloatingText(t->position, "LEVEL UP!", YELLOW, true);
    SpawnParticles(t->position, 60, YELLOW, Fade(YELLOW, 0.0f), 120.0f, 10.0f, 3.0f, false);
}

void GrantHeroXP(int xp) {
    Hero* h = &game.hero;
    h->xp += xp;
    // AddFloatingText(h->position, TextFormat("+%d XP", xp), COLOR_AETHER_RES, false);

    while (h->xp >= h->xpToNextLevel) {
        LevelUpHero();
    }
}

void LevelUpHero() {
    Hero* h = &game.hero;
    h->xp -= h->xpToNextLevel;
    h->level++;
    h->xpToNextLevel = (int)(h->xpToNextLevel * 1.6f);
    h->skillPoints++;
    ApplyHeroSkills();
    AddFloatingText(h->position, "HERO LEVEL UP!", COLOR_AETHER_RES, true);
    SpawnParticles(h->position, 70, COLOR_AETHER_RES, Fade(COLOR_AETHER_RES, 0.0f), 140.0f, 12.0f, 4.0f, false);
}


// Calculates damage reduction and increases from status effects.
float CalculateDamage(float baseDamage, DamageType type, Enemy* target) {
    float damage = baseDamage;
    float energyMult = 1.0f;
    float physicalMult = 1.0f;

    // Apply Debuffs (Weaken, Brittle, Melted Armor)
    for (int i = 0; i < target->statusCount; i++) {
        if (target->status[i].type == STATUS_WEAKEN) {
            energyMult *= target->status[i].intensity;
        }
        if (target->status[i].type == STATUS_MELTED_ARMOR || target->status[i].type == STATUS_BRITTLE) {
            physicalMult *= target->status[i].intensity;
        }
    }

    // Guard against division by zero.
    switch (type) {
        case DMG_PHYSICAL: {
            damage *= physicalMult;
            // Clamp effective armor to avoid 100 + armor == 0
            float effArmor = fmaxf(target->armor, -99.0f); // at least -99 so denominator >= 1
            damage *= (100.0f / (100.0f + effArmor));
        } break;
        case DMG_ENERGY: {
            damage *= energyMult;
            float effResist = fmaxf(target->energyResist, -99.0f);
            damage *= (100.0f / (100.0f + effResist));
        } break;
        case DMG_TRUE:
            break;
    }
    return damage > 0.5f ? damage : 0.5f;
}

void ApplyStatusEffect(Enemy* enemy, StatusEffect type, float duration, float intensity) {
    if (!enemy || !enemy->active || type == STATUS_NONE) return;

    // Bosses resist status effects
    if (enemy->type == ENEMY_BOSS) {
        duration *= 0.5f;
        if (type == STATUS_STUN) duration *= 0.3f;
        if (type == STATUS_SLOW) intensity *= 0.5f;
    }

    // Check if status exists and refresh/upgrade
    for (int i = 0; i < enemy->statusCount; i++) {
        if (enemy->status[i].type == type) {

            // Implement "Strongest Wins" stacking logic.
            // Prevents weak+long effects from extending strong+short effects.

            if (intensity > enemy->status[i].intensity) {
                // New effect is stronger, overwrite completely.
                enemy->status[i].intensity = intensity;
                enemy->status[i].duration = duration;
                enemy->status[i].timer = 0;
            } else if (intensity == enemy->status[i].intensity) {
                // Same intensity, refresh duration if new application is longer than remaining duration.
                float remaining = enemy->status[i].duration - enemy->status[i].timer;
                if (duration > remaining) {
                    enemy->status[i].duration = duration;
                    enemy->status[i].timer = 0;
                }
            }
            // If new intensity is weaker, we ignore the application entirely.
            return;
        }
    }

    // Apply new status
    if (enemy->statusCount < MAX_STATUS_EFFECTS) {
        enemy->status[enemy->statusCount] = (ActiveStatus){type, duration, intensity, 0};
        enemy->statusCount++;
    }
}

void ProcessStatusEffects(Enemy* enemy, float dt) {
    float damage_over_time = 0.0f;
    float speed_multiplier = 1.0f;
    bool stunned = false;

    // Iterate through effects
    for (int i = 0; i < enemy->statusCount; ) {
        ActiveStatus* effect = &enemy->status[i];
        effect->timer += dt;

        if (effect->timer >= effect->duration) {
            // Effect expired, remove it
            if (i < enemy->statusCount - 1) {
                 enemy->status[i] = enemy->status[enemy->statusCount - 1];
            }
            enemy->statusCount--;
            continue;
        }

        // Apply effects
        switch (effect->type) {
            case STATUS_BURN:
                damage_over_time += effect->intensity * dt;
                break;
            case STATUS_STUN:
                stunned = true;
                break;
            case STATUS_SLOW:
                 if (1.0f - effect->intensity < speed_multiplier) {
                    speed_multiplier = 1.0f - effect->intensity;
                }
                break;
            default: break;
        }
        i++;
    }

    // Apply accumulated DoT
    if (damage_over_time > 0) {
        // Apply float DoT damage
        enemy->hp -= damage_over_time;
    }

    // Apply movement effects
    if (stunned) {
        enemy->speed = 0;
    } else {
        enemy->speed = enemy->baseSpeed * speed_multiplier;
    }
}


void HandleEnemyDeath(int enemyIndex, int sourceTowerIndex) {
    if (enemyIndex < 0 || enemyIndex >= MAX_ENEMIES) return;
    Enemy* e = &game.enemies[enemyIndex];
    if (!e->active) return;

    const Vector2 deathPosition = e->position;
    const int deathXP = e->xpValue;
    e->active = false;

    // Rewards
    game.gold += e->goldValue;
    game.aether += e->aetherValue;

    // Visual Feedback
    // Use formatted text helper
    AddFloatingTextFmt(e->position, COLOR_GOLD, false, "+%dG", e->goldValue);
    if (e->aetherValue > 0) {
        AddFloatingTextFmt((Vector2){e->position.x, e->position.y + 20}, COLOR_AETHER_RES, false, "+%dA", e->aetherValue);
    }
    SpawnParticles(e->position, 40, RED, Fade(GRAY, 0.0f), 100.0f, 8.0f, 2.0f, true);

    // Spawner enemy logic
    if (e->type == ENEMY_SPAWNER) {
        int minionsToSpawn = 4;
        for (int i = 0; i < minionsToSpawn; i++) {
            Vector2 offset = {(float)GetRandomValue(-20, 20), (float)GetRandomValue(-20, 20)};
            SpawnEnemy(ENEMY_MINION, Vector2Add(deathPosition, offset));
        }
    }

    // XP Distribution
    // Grant XP to the killing tower
    if (sourceTowerIndex >= 0 && sourceTowerIndex < MAX_TOWERS) {
        GrantXP(sourceTowerIndex, deathXP);
        game.towers[sourceTowerIndex].kills++;
    }

    // Grant XP to the Hero
    if (sourceTowerIndex == -2) {
         GrantHeroXP(deathXP);
    } else {
         GrantHeroXP((int)(deathXP * 0.4f)); // Global share
    }
}

//----------------------------------------------------------------------------------
// Utility Functions Implementation
//----------------------------------------------------------------------------------

static inline Enemy* GetEnemyFromPair(int index, int id) {
    if (index >= 0 && index < MAX_ENEMIES) {
        Enemy* e = &game.enemies[index];
        if (e->active && e->id == id) return e;
    }
    return NULL;
}

Vector2 WorldToTile(Vector2 worldPos) {
    int x = (int)floorf(worldPos.x / TILE_SIZE);
    int y = (int)floorf(worldPos.y / TILE_SIZE);
    return (Vector2){ (float)x, (float)y };
}

Vector2 TileToWorldCenter(int x, int y) {
    return (Vector2){ x * TILE_SIZE + TILE_SIZE/2.0f, y * TILE_SIZE + TILE_SIZE/2.0f };
}

// Helper function implementation.
// Finds the closest point on a line segment AB to a point P.
Vector2 ClosestPointOnSegment(Vector2 p, Vector2 a, Vector2 b) {
    Vector2 ab = Vector2Subtract(b, a);
    float lengthSqr = Vector2LengthSqr(ab);

    if (lengthSqr == 0.0f) return a; // A = B, segment is a point.

    // Project P onto the line defined by A + t*AB.
    // The parameter t is calculated as: t = dot((P-A), AB) / lengthSqr(AB)
    float t = Vector2DotProduct(Vector2Subtract(p, a), ab) / lengthSqr;

    // Clamp t to the range [0, 1] to stay within the segment AB.
    // Using Clamp from raymath.h as it is used elsewhere in the provided code.
    t = Clamp(t, 0.0f, 1.0f);

    // Closest point is A + t*AB
    return Vector2Add(a, Vector2Scale(ab, t));
}

bool IsTileBuildable(int x, int y) {
    if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT) return false;
    if (game.map.tiles[y][x] != 0) return false;
    return !game.occupied[y][x];
}

Enemy* GetEnemyById(int id) {
    if (id <= 0) return NULL;
    for (int i = 0; i < MAX_ENEMIES; i++) {
        if (game.enemies[i].active && game.enemies[i].id == id) {
            return &game.enemies[i];
        }
    }
    return NULL;
}

int GetEnemyIndexById(int id) {
     if (id <= 0) return -1;
    for (int i = 0; i < MAX_ENEMIES; i++) {
        if (game.enemies[i].active && game.enemies[i].id == id) {
            return i;
        }
    }
    return -1;
}

float LerpAngle(float start, float end, float amount) {
    float difference = fmodf(end - start + 360.0f, 360.0f);
    if (difference > 180.0f) {
        difference -= 360.0f;
    }
    return start + difference * amount;
}


// VFX Utility Functions (Enhanced)

void UpdateVFX(float dt) {
    // Update Floating Texts (Enhanced dynamics)
    for (int i = 0; i < MAX_FLOATING_TEXT; i++) {
        if (game.floatingTexts[i].active) {
            game.floatingTexts[i].lifetime -= dt;
            // Apply velocity
            game.floatingTexts[i].position.y += game.floatingTexts[i].velocityY * dt;
            // Apply deceleration (float up slows down)
            game.floatingTexts[i].velocityY = Lerp(game.floatingTexts[i].velocityY, 0.0f, 3.0f * dt);

            if (game.floatingTexts[i].lifetime <= 0) {
                game.floatingTexts[i].active = false;
            }
        }
    }

    // Precompute damping factors once per frame
    float clamped = Clamp(dt, 0.0f, 0.1f);
    float dampingGravityFactor = powf(0.99f, clamped * 60.0f);
    float dampingNoGravFactor = powf(0.95f, clamped * 60.0f);

    for (int i = 0; i < MAX_PARTICLES; i++) {
        if (!game.particles[i].active) continue;
        Particle* p = &game.particles[i];
        p->life += dt;
        if (p->life >= p->maxLife) { p->active = false; continue; }

        if (p->gravity) p->velocity.y += 200.0f * dt;
        p->position = Vector2Add(p->position, Vector2Scale(p->velocity, dt));

        float df = p->gravity ? dampingGravityFactor : dampingNoGravFactor;
        p->velocity = Vector2Scale(p->velocity, df);
    }
}


void SpawnParticles(Vector2 position, int count, Color startColor, Color endColor, float speed, float sizeStart, float sizeEnd, bool gravity) {
    for (int i = 0; i < count; i++) {
        int index = -1;
        for (int j = 0; j < MAX_PARTICLES; j++) {
            if (!game.particles[j].active) { index = j; break; }
        }

        if (index != -1) {
            Particle* p = &game.particles[index];
            p->active = true;
            p->position = position;
            p->startColor = startColor;
            p->endColor = endColor;
            p->life = 0;
            p->maxLife = GetRandomValue(5, 20) / 10.0f;
            p->startSize = sizeStart * (GetRandomValue(8, 12) / 10.0f);
            p->endSize = sizeEnd;
            p->gravity = gravity;

            float angle = GetRandomValue(0, 360) * DEG2RAD;
            float magnitude = (float)GetRandomValue(10, (int)speed);
            p->velocity = (Vector2){ cosf(angle) * magnitude, sinf(angle) * magnitude };
            if (gravity && p->velocity.y > 0) p->velocity.y *= -0.5f;
        }
    }
}

void AddFloatingText(Vector2 position, const char* text, Color color, bool critical) {
    int index = -1;
    float minLife = 100.0f;
    for (int i = 0; i < MAX_FLOATING_TEXT; i++) {
        if (!game.floatingTexts[i].active) { index = i; break; }
        if (game.floatingTexts[i].lifetime < minLife) {
            minLife = game.floatingTexts[i].lifetime;
            index = i;
        }
    }

    if (index != -1) {
        FloatingText* ft = &game.floatingTexts[index];
        ft->active = true;
        ft->position = (Vector2){position.x + GetRandomValue(-5, 5), position.y + GetRandomValue(-5, 5)};
        strncpy(ft->text, text, 31);
        ft->text[31] = '\0';
        ft->color = color;
        ft->lifetime = critical ? 2.0f : 1.5f;
        ft->critical = critical;
        ft->velocityY = critical ? -80.0f : -40.0f;
    }
}

// Implement formatted floating text helper
void AddFloatingTextFmt(Vector2 position, Color color, bool critical, const char* fmt, ...) {
    int index = -1;
    float minLife = 100.0f;
    for (int i = 0; i < MAX_FLOATING_TEXT; i++) {
        if (!game.floatingTexts[i].active) { index = i; break; }
        if (game.floatingTexts[i].lifetime < minLife) {
            minLife = game.floatingTexts[i].lifetime;
            index = i;
        }
    }

    if (index != -1) {
        FloatingText* ft = &game.floatingTexts[index];
        ft->active = true;
        ft->position = (Vector2){position.x + GetRandomValue(-5, 5), position.y + GetRandomValue(-5, 5)};
        ft->color = color;
        ft->lifetime = critical ? 2.0f : 1.5f;
        ft->critical = critical;
        ft->velocityY = critical ? -80.0f : -40.0f;

        va_list args;
        va_start(args, fmt);
        vsnprintf(ft->text, sizeof(ft->text), fmt, args);
        va_end(args);

        ft->text[sizeof(ft->text) - 1] = '\0';
    }
}


void ScreenShake(float intensity, float duration) {
    if (intensity > game.screenShakeIntensity || game.screenShakeTime <= 0) {
        game.screenShakeIntensity = intensity;
        game.screenShakeTime = duration;
        // Store the initial duration
        game.screenShakeDuration = duration;
    }
}

// GUI/Data Utility Functions

int GetTowerCost(TowerType type) {
    switch (type) {
        case TOWER_PULSE: return 100;
        case TOWER_CANNON: return 250;
        case TOWER_CRYO: return 200;
        case TOWER_TESLA: return 400;
        // T4 Costs (Paid on upgrade)
        case TOWER_T4_PULSE_REPEATER: return 800;
        case TOWER_T4_PULSE_SNIPER: return 1000;
        case TOWER_T4_CANNON_MORTAR: return 1500;
        case TOWER_T4_CANNON_VULCAN: return 900;
        case TOWER_T4_CRYO_BLIZZARD: return 700;
        case TOWER_T4_CRYO_FREEZER: return 850;
        case TOWER_T4_TESLA_CHAIN: return 1100;
        case TOWER_T4_TESLA_STORM: return 1300;
        default: return 99999;
    }
}

int GetTowerAetherCost(TowerType type) {
    // Aether is only required for T4 upgrades.
    if (type >= TOWER_T4_PULSE_REPEATER) {
        return 50 + (GetTowerCost(type) / 20);
    }
    return 0;
}


const char* GetTowerName(TowerType type) {
    switch (type) {
        case TOWER_PULSE: return "Pulse Emitter [1]";
        case TOWER_CANNON: return "Aether Cannon [2]";
        case TOWER_CRYO: return "Cryo Beam [3]";
        case TOWER_TESLA: return "Tesla Coil [4]";
        // T4 Names
        case TOWER_T4_PULSE_REPEATER: return "T4: Pulse Repeater";
        case TOWER_T4_PULSE_SNIPER: return "T4: Marksman Laser";
        case TOWER_T4_CANNON_MORTAR: return "T4: Orbital Mortar";
        case TOWER_T4_CANNON_VULCAN: return "T4: Vulcan Gatling";
        case TOWER_T4_CRYO_BLIZZARD: return "T4: Blizzard Field";
        case TOWER_T4_CRYO_FREEZER: return "T4: Deep Freezer";
        case TOWER_T4_TESLA_CHAIN: return "T4: Chain Lightning";
        case TOWER_T4_TESLA_STORM: return "T4: Storm Caller";
        default: return "Unknown";
    }
}

const char* GetTowerDescription(TowerType type) {
     switch (type) {
        case TOWER_PULSE: return "Rapid-fire energy weapon. Effective against most targets.";
        case TOWER_CANNON: return "Fires explosive physical shells. Deals AoE damage.\nSYNERGY: Applies Burn and Melted Armor.";
        case TOWER_CRYO: return "Continuous energy beam that slows a target.\nSYNERGY: Applies Brittle (Increased Physical Dmg Taken).";
        case TOWER_TESLA: return "High-damage energy attacks with a chance to stun the target.";
        // T4 Descriptions
        case TOWER_T4_PULSE_REPEATER: return "Upgraded Pulse Emitter with extreme fire rate. Overwhelms targets with energy.";
        case TOWER_T4_PULSE_SNIPER: return "Long-range, slow-firing laser that deals massive energy damage.";
        case TOWER_T4_CANNON_MORTAR: return "Global range artillery. Fires slow-moving shells with a massive explosion radius.\nUses predictive ballistic targeting.";
        case TOWER_T4_CANNON_VULCAN: return "High-speed physical Gatling gun. Shreds armor and applies Burn rapidly.";
        case TOWER_T4_CRYO_BLIZZARD: return "Creates a persistent slowing field around the tower, affecting all enemies within.";
        case TOWER_T4_CRYO_FREEZER: return "Upgraded Cryo Beam that completely freezes (stuns) the target for a duration.";
        case TOWER_T4_TESLA_CHAIN: return "Lightning attack that chains to multiple nearby enemies.";
        case TOWER_T4_TESLA_STORM: return "High damage Tesla Coil with increased stun chance and damage.";
        default: return "No description available.";
    }
}

bool GuiButton(Rectangle bounds, const char* text, bool selected, bool enabled) {
    Vector2 mousePos = GetMousePosition();
    bool hovered = CheckCollisionPointRec(mousePos, bounds);
    bool clicked = false;

    Color bgColor = COLOR_UI_ACCENT;
    Color textColor = COLOR_TEXT_PRIMARY;
    Color borderColor = COLOR_GRID;

    if (!enabled) {
        bgColor = ColorBrightness(COLOR_UI_ACCENT, -0.4f);
        textColor = COLOR_TEXT_MUTED;
    } else if (selected) {
        bgColor = COLOR_ENERGY;
        textColor = BLACK;
        borderColor = YELLOW;
    } else if (hovered) {
        bgColor = ColorBrightness(COLOR_UI_ACCENT, 0.2f);
        borderColor = YELLOW;
        if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON)) {
            clicked = true;
        }
    }

    DrawRectangleRounded(bounds, 0.1f, 8, bgColor);
    // Using the compatibility wrapper for DrawRectangleRoundedLines
    AVDrawRectangleRoundedLinesEx(bounds, 0.1f, 8, 2.0f, borderColor);

    int textSize = 18;
    int textWidth = MeasureText(text, textSize);
    DrawText(text, bounds.x + bounds.width/2 - textWidth/2, bounds.y + bounds.height/2 - textSize/2, textSize, textColor);

    return clicked && enabled;
}

void SetTooltip(const char* title, const char* description, Rectangle bounds) {
    if (CheckCollisionPointRec(GetMousePosition(), bounds)) {
        game.tooltip.title = title;
        game.tooltip.description = description;
        game.tooltip.bounds = bounds;
        game.tooltip.visible = true;
    }
}