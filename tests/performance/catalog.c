#define _POSIX_C_SOURCE 200809L
#include "aetherium.h"
#include <inttypes.h>
#include <stdint.h>
#include <time.h>

#define DECLARE(prefix)                                                                            \
    int prefix##GetTowerCost(TowerType);                                                           \
    int prefix##GetTowerAetherCost(TowerType);                                                     \
    void prefix##ConfigureTowerStats(Tower *);
DECLARE(before_)
DECLARE(after_)
typedef struct {
    const char *name;
    int (*cost)(TowerType);
    int (*aether)(TowerType);
    void (*configure)(Tower *);
} Implementation;
static const Implementation implementations[] = {
    {"before", before_GetTowerCost, before_GetTowerAetherCost, before_ConfigureTowerStats},
    {"after", after_GetTowerCost, after_GetTowerAetherCost, after_ConfigureTowerStats},
    {"c", GetTowerCost, GetTowerAetherCost, ConfigureTowerStats},
};
static double now(void) {
    struct timespec time;
    clock_gettime(CLOCK_MONOTONIC, &time);
    return time.tv_sec + time.tv_nsec / 1e9;
}
static uint64_t hash_bytes(const void *data, size_t count) {
    uint64_t hash = UINT64_C(14695981039346656037);
    const unsigned char *bytes = data;
    while (count--) {
        hash ^= *bytes++;
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}
int main(int argc, char **argv) {
    if (argc != 4)
        return 2;
    const Implementation *implementation = NULL;
    for (unsigned i = 0; i < sizeof implementations / sizeof *implementations; i++)
        if (!strcmp(argv[1], implementations[i].name))
            implementation = &implementations[i];
    if (!implementation)
        return 2;
    const char *mode = argv[2];
    long rounds = strtol(argv[3], NULL, 10);
    if (rounds <= 0)
        return 2;
    Tower towers[64];
    memset(towers, 0, sizeof towers);
    for (int i = 0; i < 64; i++) {
        towers[i].type = i % 12;
        towers[i].stats.level = 1 + (i / 12) % 3;
        towers[i].stats.xp = 73;
        if (!strcmp(mode, "configure-level1") || !strcmp(mode, "configure-level2") ||
            !strcmp(mode, "configure-level3")) {
            towers[i].type = i % 4;
            towers[i].stats.level = mode[strlen(mode) - 1] - '0';
        } else if (!strcmp(mode, "configure-specialized")) {
            towers[i].type = 4 + i % 8;
            towers[i].stats.level = 3;
        } else if (!strcmp(mode, "configure-high-level")) {
            towers[i].stats.level = 31;
        }
    }
    uint64_t sum = 0;
    double start = now();
    if (!strncmp(mode, "configure-", 10)) {
        for (long i = 0; i < rounds; i++)
            implementation->configure(&towers[i & 63]);
    } else if (!strcmp(mode, "aether-cost")) {
        for (long i = 0; i < rounds; i++)
            sum += implementation->aether((TowerType)(4 + (i & 7)));
    } else if (!strcmp(mode, "gold-cost")) {
        for (long i = 0; i < rounds; i++)
            sum += implementation->cost(towers[i & 63].type);
    } else {
        return 2;
    }
    double elapsed = now() - start;
    printf("RESULT %.9f %016" PRIx64 "\n", elapsed, hash_bytes(towers, sizeof towers) ^ sum);
    return 0;
}
