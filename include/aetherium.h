/* Generated ABI contract; regenerate with make regenerate. */
#ifndef AETHERIUM_H
#define AETHERIUM_H
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

extern GameData game;

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


//----------------------------------------------------------------------------------
// Main Entry Point
//----------------------------------------------------------------------------------


#endif
