#include "test.h"
static void invalid_status_applications_have_no_effect(void) {
    Enemy *e = test_enemy(0, 0, 0);
    ApplyStatusEffect(NULL, STATUS_BURN, 5, 1);
    ApplyStatusEffect(e, STATUS_NONE, 5, 1);
    CHECK(e->statusCount == 0);
    e->active = false;
    ApplyStatusEffect(e, STATUS_BURN, 5, 1);
    CHECK(e->statusCount == 0);
}
static void stronger_status_replaces_intensity_and_restarts_timer(void) {
    Enemy *e = test_enemy(0, 0, 0);
    ApplyStatusEffect(e, STATUS_SLOW, 5, .2f);
    e->status[0].timer = 3;
    ApplyStatusEffect(e, STATUS_SLOW, 2, .8f);
    CHECK(e->statusCount == 1);
    NEAR(e->status[0].intensity, .8f, 0);
    NEAR(e->status[0].duration, 2, 0);
    NEAR(e->status[0].timer, 0, 0);
}
static void weaker_longer_status_does_not_extend_a_stronger_effect(void) {
    Enemy *e = test_enemy(0, 0, 0);
    ApplyStatusEffect(e, STATUS_SLOW, 2, .8f);
    e->status[0].timer = 1;
    ApplyStatusEffect(e, STATUS_SLOW, 100, .2f);
    NEAR(e->status[0].intensity, .8f, 0);
    NEAR(e->status[0].duration, 2, 0);
    NEAR(e->status[0].timer, 1, 0);
}
static void equal_intensity_refreshes_only_when_remaining_duration_increases(void) {
    Enemy *e = test_enemy(0, 0, 0);
    ApplyStatusEffect(e, STATUS_BURN, 5, 10);
    e->status[0].timer = 2;
    ApplyStatusEffect(e, STATUS_BURN, 2, 10);
    NEAR(e->status[0].timer, 2, 0);
    ApplyStatusEffect(e, STATUS_BURN, 4, 10);
    NEAR(e->status[0].timer, 0, 0);
    NEAR(e->status[0].duration, 4, 0);
}
static void bosses_resist_stun_and_slow(void) {
    Enemy *e = test_enemy(0, 0, 0);
    e->type = ENEMY_BOSS;
    ApplyStatusEffect(e, STATUS_STUN, 10, 1);
    ApplyStatusEffect(e, STATUS_SLOW, 10, .8f);
    NEAR(e->status[0].duration, 1.5f, .00001f);
    NEAR(e->status[1].duration, 5, 0);
    NEAR(e->status[1].intensity, .4f, 0);
}
static void status_pool_never_exceeds_six_slots(void) {
    Enemy *e = test_enemy(0, 0, 0);
    for (int bit = 0; bit < 20; bit++) {
        ApplyStatusEffect(e, (StatusEffect)(1 << bit), 5, 1);
        CHECK(e->statusCount <= 6);
    }
    CHECK(e->statusCount == 6);
}
static void expiration_processes_a_swapped_record_in_the_same_frame(void) {
    Enemy *e = test_enemy(0, 0, 0);
    ApplyStatusEffect(e, STATUS_SLOW, 1, .5f);
    ApplyStatusEffect(e, STATUS_BURN, 1, 5);
    ApplyStatusEffect(e, STATUS_STUN, 1, 1);
    ProcessStatusEffects(e, 1);
    CHECK(e->statusCount == 0);
    NEAR(e->speed, e->baseSpeed, 0);
    NEAR(e->hp, 100, 0);
}
static void burn_damage_is_fractional_and_stun_overrides_slow(void) {
    Enemy *e = test_enemy(0, 0, 0);
    ApplyStatusEffect(e, STATUS_BURN, 5, 10);
    ApplyStatusEffect(e, STATUS_SLOW, 5, .5f);
    ApplyStatusEffect(e, STATUS_STUN, 5, 1);
    ProcessStatusEffects(e, .25f);
    NEAR(e->hp, 97.5f, 0);
    NEAR(e->speed, 0, 0);
}
static void expired_slow_restores_base_speed(void) {
    Enemy *e = test_enemy(0, 0, 0);
    ApplyStatusEffect(e, STATUS_SLOW, 1, .75f);
    ProcessStatusEffects(e, .5f);
    NEAR(e->speed, 20, 0);
    ProcessStatusEffects(e, .5f);
    NEAR(e->speed, 80, 0);
}
void suite_status(void) {
    RUN(invalid_status_applications_have_no_effect);
    RUN(stronger_status_replaces_intensity_and_restarts_timer);
    RUN(weaker_longer_status_does_not_extend_a_stronger_effect);
    RUN(equal_intensity_refreshes_only_when_remaining_duration_increases);
    RUN(bosses_resist_stun_and_slow);
    RUN(status_pool_never_exceeds_six_slots);
    RUN(expiration_processes_a_swapped_record_in_the_same_frame);
    RUN(burn_damage_is_fractional_and_stun_overrides_slow);
    RUN(expired_slow_restores_base_speed);
}
