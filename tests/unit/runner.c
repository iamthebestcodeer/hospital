#include "test.h"
#include <stdio.h>
#include <stdlib.h>
static unsigned tests, assertions;
static const char *current_test;
void test_check(bool passed, const char *expression, const char *file, int line) {
    assertions++;
    if (!passed) {
        fprintf(stderr, "FAIL %s: %s (%s:%d)\n", current_test, expression, file, line);
        exit(EXIT_FAILURE);
    }
}
void test_near(float actual, float expected, float tolerance, const char *file, int line) {
    assertions++;
    if (!isfinite(actual) || fabsf(actual - expected) > tolerance) {
        fprintf(stderr, "FAIL %s: expected %.9g +/- %.9g, got %.9g (%s:%d)\n", current_test,
                expected, tolerance, actual, file, line);
        exit(EXIT_FAILURE);
    }
}
void test_run(const char *name, void (*test)(void)) {
    current_test = name;
    test_reset();
    test();
    tests++;
    printf("  PASS %s\n", name);
}
int main(void) {
    SetTraceLogLevel(LOG_NONE);
    suite_geometry();
    suite_damage();
    suite_status();
    suite_towers();
    suite_progression();
    suite_session();
    suite_hero();
    suite_enemies();
    suite_projectiles();
    suite_effects();
    suite_abi();
    printf("PASS: %u named unit tests, %u assertions; no window or renderer.\n", tests, assertions);
    return 0;
}
