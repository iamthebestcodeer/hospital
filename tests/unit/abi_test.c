#include "test.h"
#include <stdint.h>
#include <stddef.h>
typedef struct {
    uint64_t gp[6];
    uint64_t fp[8];
} AbiArguments;
_Static_assert(offsetof(AbiArguments, fp) == 48 && sizeof(AbiArguments) == 112,
               "register probe argument layout must match NASM");
int av_test_preserves_registers(void (*entry)(void), const AbiArguments *arguments);
float __real_GetAimToleranceDegrees(TowerType type);
extern void av_test_clobber_rbp(void), av_test_clobber_rbx(void), av_test_clobber_r12(void);
extern void av_test_clobber_r13(void), av_test_clobber_r14(void), av_test_clobber_r15(void);
static uint64_t scalar(float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof bits);
    return bits;
}
static uint64_t vector(float x, float y) {
    Vector2 value = {x, y};
    uint64_t bits;
    memcpy(&bits, &value, sizeof bits);
    return bits;
}
#define PROBE(function, ...)                                                                       \
    do {                                                                                           \
        AbiArguments arguments = {__VA_ARGS__};                                                    \
        CHECK(av_test_preserves_registers((void (*)(void))function, &arguments));                  \
    } while (0)
static void domain_calls_preserve_all_system_v_callee_saved_registers(void) {
    Enemy *e = test_enemy(0, 100, 100);
    Tower t = {.type = TOWER_PULSE, .stats.level = 1};
    PROBE(ApplyStatusEffect, .gp = {(uintptr_t)e, STATUS_BURN}, .fp = {scalar(2), scalar(5)});
    PROBE(ProcessStatusEffects, .gp = {(uintptr_t)e}, .fp = {scalar(.01f)});
    PROBE(CalculateDamage, .gp = {DMG_PHYSICAL, (uintptr_t)e}, .fp = {scalar(100)});
    PROBE(WorldToTile, .fp = {vector(-1, 100)});
    PROBE(TileToWorldCenter, .gp = {1, 2});
    PROBE(ClosestPointOnSegment, .fp = {vector(10, 5), vector(0, 0), vector(20, 0)});
    PROBE(LerpAngle, .fp = {scalar(350), scalar(10), scalar(.5f)});
    PROBE(GetEnemyById, .gp = {e->id});
    PROBE(GetEnemyIndexById, .gp = {e->id});
    PROBE(IsTileBuildable, .gp = {0, 0});
    PROBE(GetTowerCost, .gp = {TOWER_PULSE});
    PROBE(GetTowerAetherCost, .gp = {TOWER_T4_TESLA_CHAIN});
    PROBE(__real_GetAimToleranceDegrees, .gp = {TOWER_CANNON});
    PROBE(ConfigureTowerStats, .gp = {(uintptr_t)&t});
    PROBE(InitMap, .gp = {0});
}
static void nested_gameplay_calls_preserve_all_system_v_callee_saved_registers(void) {
    PROBE(PlaceTower, .gp = {0, 0, TOWER_PULSE});
    PROBE(SpawnEnemy, .gp = {ENEMY_BASIC}, .fp = {vector(100, 20)});
    Tower *t = &game.towers[0];
    Enemy *e = &game.enemies[0];
    PROBE(GrantXP, .gp = {0, 150});
    PROBE(LevelUpTower, .gp = {0});
    PROBE(GrantHeroXP, .gp = {250});
    PROBE(LevelUpHero, .gp = {0});
    PROBE(ApplyHeroSkills, .gp = {0});
    PROBE(UpdateHero, .fp = {scalar(.01f)});
    PROBE(HeroAttack, .gp = {0});
    PROBE(UpdateTowers, .fp = {scalar(.01f)});
    PROBE(FireProjectile, .gp = {(uintptr_t)t, (uintptr_t)e});
    PROBE(UpdateEnemies, .fp = {scalar(.01f)});
    PROBE(UpdateProjectiles, .fp = {scalar(.01f)});
    PROBE(SpawnParticles, .gp = {4, 0xffffffff, 0xffffffff, 0},
          .fp = {vector(0, 0), scalar(10), scalar(2), scalar(1)});
    PROBE(AddFloatingText, .gp = {(uintptr_t)"ABI", 0xffffffff, 0}, .fp = {vector(0, 0)});
    double real = 1.5;
    uint64_t real_bits;
    memcpy(&real_bits, &real, sizeof real);
    PROBE(AddFloatingTextFmt, .gp = {0xffffffff, 0, (uintptr_t)"%d %g", 42},
          .fp = {vector(0, 0), real_bits});
    PROBE(UpdateVFX, .fp = {scalar(.01f)});
    Projectile p = {.damage = 1, .sourceTowerIndex = -1};
    PROBE(ApplyDamageAndEffects, .gp = {(uintptr_t)&p, (uintptr_t)e, 0});
    PROBE(HandleProjectileImpact, .gp = {(uintptr_t)&p, (uintptr_t)e});
    PROBE(HandleEnemyDeath, .gp = {0, 0});
    PROBE(UpgradeTower, .gp = {(uintptr_t)t, TOWER_T4_PULSE_REPEATER});
    PROBE(SellTower, .gp = {0});
    PROBE(ManageWaves, .fp = {scalar(.01f)});
    PROBE(HandleInput, .gp = {0});
    PROBE(ScreenShake, .fp = {scalar(2), scalar(.3f)});
    PROBE(UpdateEnvironment, .fp = {scalar(.01f)});
    PROBE(UpdateHeroLevelUp, .fp = {scalar(.01f)});
    PROBE(UpdatePlaying, .fp = {scalar(.01f)});
    PROBE(UpdateGame, .fp = {scalar(.01f)});
    PROBE(ResetGame, .gp = {0});
}
static void register_probe_rejects_each_individual_callee_saved_register_clobber(void) {
    void (*clobbers[])(void) = {av_test_clobber_rbp, av_test_clobber_rbx, av_test_clobber_r12,
                                av_test_clobber_r13, av_test_clobber_r14, av_test_clobber_r15};
    AbiArguments arguments = {0};
    for (unsigned i = 0; i < sizeof clobbers / sizeof *clobbers; i++)
        CHECK(!av_test_preserves_registers(clobbers[i], &arguments));
}
void suite_abi(void) {
    RUN(domain_calls_preserve_all_system_v_callee_saved_registers);
    RUN(nested_gameplay_calls_preserve_all_system_v_callee_saved_registers);
    RUN(register_probe_rejects_each_individual_callee_saved_register_clobber);
}
