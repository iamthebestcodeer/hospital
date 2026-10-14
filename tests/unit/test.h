#ifndef AETHERIUM_TEST_H
#define AETHERIUM_TEST_H
#include "aetherium.h"

void test_reset(void);
void test_hold(int key);
void test_press(int key);
void test_mouse(float x, float y, int button);
Enemy *test_enemy(int index, float x, float y);
int test_particle_count(void);
int test_projectile_count(void);
void test_run(const char *name, void (*test)(void));
void test_check(bool passed, const char *expression, const char *file, int line);
void test_near(float actual, float expected, float tolerance, const char *file, int line);
#define CHECK(expression) test_check((expression), #expression, __FILE__, __LINE__)
#define NEAR(actual, expected, tolerance)                                                          \
    test_near((actual), (expected), (tolerance), __FILE__, __LINE__)
#define RUN(test) test_run(#test, test)
void suite_geometry(void);
void suite_damage(void);
void suite_status(void);
void suite_towers(void);
void suite_progression(void);
void suite_session(void);
void suite_hero(void);
void suite_enemies(void);
void suite_projectiles(void);
void suite_effects(void);
void suite_abi(void);
#endif
