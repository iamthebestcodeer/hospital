#include "test.h"
static void tile_centers_round_trip_across_the_board(void) {
    for (int y = 0; y < MAP_HEIGHT; y++)
        for (int x = 0; x < MAP_WIDTH; x++) {
            Vector2 center = TileToWorldCenter(x, y), tile = WorldToTile(center);
            NEAR(center.x, x * 40 + 20, 0);
            NEAR(center.y, y * 40 + 20, 0);
            NEAR(tile.x, x, 0);
            NEAR(tile.y, y, 0);
        }
}
static void negative_world_coordinates_floor_instead_of_truncate(void) {
    const float values[] = {-80.01f, -80, -40.01f, -40, -.01f, 0, 39.99f, 40};
    const int expected[] = {-3, -2, -2, -1, -1, 0, 0, 1};
    for (unsigned i = 0; i < sizeof values / sizeof *values; i++) {
        Vector2 tile = WorldToTile((Vector2){values[i], values[i]});
        NEAR(tile.x, expected[i], 0);
        NEAR(tile.y, expected[i], 0);
    }
}
static void projection_clamps_to_both_segment_endpoints(void) {
    Vector2 a = {10, 20}, b = {30, 20};
    Vector2 before = ClosestPointOnSegment((Vector2){0, 40}, a, b);
    Vector2 after = ClosestPointOnSegment((Vector2){50, 40}, a, b);
    NEAR(before.x, 10, 0);
    NEAR(before.y, 20, 0);
    NEAR(after.x, 30, 0);
    NEAR(after.y, 20, 0);
}
static void projection_handles_midpoints_vertical_and_zero_length_segments(void) {
    Vector2 p = ClosestPointOnSegment((Vector2){8, 5}, (Vector2){2, 0}, (Vector2){2, 10});
    NEAR(p.x, 2, 0);
    NEAR(p.y, 5, 0);
    p = ClosestPointOnSegment((Vector2){99, 99}, (Vector2){3, 7}, (Vector2){3, 7});
    NEAR(p.x, 3, 0);
    NEAR(p.y, 7, 0);
}
static void rotation_takes_the_short_route_across_zero(void) {
    NEAR(LerpAngle(350, 10, .5f), 360, .0001f);
    NEAR(LerpAngle(10, 350, .5f), 0, .0001f);
    NEAR(LerpAngle(45, 270, 0), 45, 0);
}
static void map_has_offscreen_endpoints_and_only_orthogonal_segments(void) {
    CHECK(game.map.waypointCount == 13);
    NEAR(game.map.waypoints[0].x, -60, 0);
    NEAR(game.map.waypoints[12].x, 1020, 0);
    for (int i = 1; i < game.map.waypointCount; i++) {
        Vector2 a = game.map.waypoints[i - 1], b = game.map.waypoints[i];
        CHECK((a.x == b.x) != (a.y == b.y));
    }
}
static void buildability_rejects_bounds_path_and_occupied_tiles(void) {
    CHECK(!IsTileBuildable(-1, 0));
    CHECK(!IsTileBuildable(24, 0));
    CHECK(!IsTileBuildable(0, -1));
    CHECK(!IsTileBuildable(0, 20));
    CHECK(!IsTileBuildable(0, 3));
    CHECK(IsTileBuildable(0, 0));
    game.occupied[0][0] = true;
    CHECK(!IsTileBuildable(0, 0));
}
static void enemy_lookup_ignores_dead_slots_and_invalid_ids(void) {
    CHECK(GetEnemyById(0) == NULL);
    CHECK(GetEnemyById(-1) == NULL);
    Enemy *enemy = test_enemy(299, 10, 20);
    CHECK(GetEnemyById(300) == enemy);
    CHECK(GetEnemyIndexById(300) == 299);
    enemy->active = false;
    CHECK(GetEnemyById(300) == NULL);
    CHECK(GetEnemyIndexById(300) == -1);
}
void suite_geometry(void) {
    RUN(tile_centers_round_trip_across_the_board);
    RUN(negative_world_coordinates_floor_instead_of_truncate);
    RUN(projection_clamps_to_both_segment_endpoints);
    RUN(projection_handles_midpoints_vertical_and_zero_length_segments);
    RUN(rotation_takes_the_short_route_across_zero);
    RUN(map_has_offscreen_endpoints_and_only_orthogonal_segments);
    RUN(buildability_rejects_bounds_path_and_occupied_tiles);
    RUN(enemy_lookup_ignores_dead_slots_and_invalid_ids);
}
