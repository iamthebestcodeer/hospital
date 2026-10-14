#include "test.h"
static void zero_and_negative_particle_requests_do_not_advance_rng(void) {
    SetRandomSeed(99);
    int expected = GetRandomValue(0, 10000);
    SetRandomSeed(99);
    SpawnParticles((Vector2){1, 2}, 0, RED, BLUE, 10, 2, 1, false);
    SpawnParticles((Vector2){1, 2}, -10, RED, BLUE, 10, 2, 1, false);
    CHECK(test_particle_count() == 0);
    CHECK(GetRandomValue(0, 10000) == expected);
}
static void particle_bursts_use_lowest_free_slots_and_stop_at_capacity(void) {
    for (int i = 0; i < MAX_PARTICLES; i++)
        game.particles[i].active = true;
    game.particles[3].active = false;
    game.particles[9].active = false;
    SpawnParticles((Vector2){17, 19}, 100, RED, BLUE, 10, 2, 1, false);
    CHECK(test_particle_count() == MAX_PARTICLES);
    NEAR(game.particles[3].position.x, 17, 0);
    NEAR(game.particles[9].position.y, 19, 0);
}
static void particles_expire_at_the_exact_lifetime_boundary(void) {
    Particle *p = &game.particles[0];
    p->active = true;
    p->life = .5f;
    p->maxLife = 1;
    UpdateVFX(.5f);
    CHECK(!p->active);
}
static void gravity_changes_velocity_before_integrating_position(void) {
    Particle *p = &game.particles[0];
    p->active = true;
    p->gravity = true;
    p->maxLife = 10;
    p->velocity = (Vector2){10, 20};
    UpdateVFX(.1f);
    NEAR(p->position.x, 1, .00001f);
    NEAR(p->position.y, 4, .00001f);
}
static void inactive_effects_remain_byte_for_byte_unchanged(void) {
    Particle before = game.particles[0];
    FloatingText text = game.floatingTexts[0];
    UpdateVFX(.016f);
    CHECK(!memcmp(&before, &game.particles[0], sizeof before));
    CHECK(!memcmp(&text, &game.floatingTexts[0], sizeof text));
}
static void plain_text_is_truncated_and_always_null_terminated(void) {
    AddFloatingText((Vector2){10, 20}, "abcdefghijklmnopqrstuvwxyz0123456789", RED, false);
    CHECK(!strcmp(game.floatingTexts[0].text, "abcdefghijklmnopqrstuvwxyz01234"));
}
static void formatted_text_handles_integer_and_float_arguments_on_the_stack(void) {
    AddFloatingTextFmt((Vector2){10, 20}, RED, true, "%d/%d/%d/%d/%d", 11, 22, 33, 44, 55);
    CHECK(!strcmp(game.floatingTexts[0].text, "11/22/33/44/55"));
    AddFloatingTextFmt((Vector2){10, 20}, BLUE, false, "%g/%g/%g/%g/%g/%g/%g/%g/%g", 1., 2., 3., 4.,
                       5., 6., 7., 8., 9.);
    CHECK(!strcmp(game.floatingTexts[1].text, "1/2/3/4/5/6/7/8/9"));
}
static void full_text_pool_replaces_the_lowest_remaining_lifetime(void) {
    for (int i = 0; i < MAX_FLOATING_TEXT; i++) {
        game.floatingTexts[i].active = true;
        game.floatingTexts[i].lifetime = 1;
    }
    game.floatingTexts[71].lifetime = .01f;
    AddFloatingText((Vector2){0, 0}, "replacement", RED, true);
    CHECK(!strcmp(game.floatingTexts[71].text, "replacement"));
    NEAR(game.floatingTexts[71].lifetime, 2, 0);
}
static void screen_shake_only_replaces_an_active_shake_with_a_stronger_one(void) {
    ScreenShake(10, 2);
    ScreenShake(5, 10);
    NEAR(game.screenShakeIntensity, 10, 0);
    NEAR(game.screenShakeDuration, 2, 0);
    ScreenShake(15, 1);
    NEAR(game.screenShakeIntensity, 15, 0);
    NEAR(game.screenShakeDuration, 1, 0);
    game.screenShakeTime = 0;
    ScreenShake(1, 5);
    NEAR(game.screenShakeIntensity, 1, 0);
}
void suite_effects(void) {
    RUN(zero_and_negative_particle_requests_do_not_advance_rng);
    RUN(particle_bursts_use_lowest_free_slots_and_stop_at_capacity);
    RUN(particles_expire_at_the_exact_lifetime_boundary);
    RUN(gravity_changes_velocity_before_integrating_position);
    RUN(inactive_effects_remain_byte_for_byte_unchanged);
    RUN(plain_text_is_truncated_and_always_null_terminated);
    RUN(formatted_text_handles_integer_and_float_arguments_on_the_stack);
    RUN(full_text_pool_replaces_the_lowest_remaining_lifetime);
    RUN(screen_shake_only_replaces_an_active_shake_with_a_stronger_one);
}
