const ray = @import("raylib.zig");
pub fn main() !void {
    ray.InitWindow(960, 540, "My Window Name");
    ray.SetTargetFPS(144);
    defer ray.CloseWindow();

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        ray.ClearBackground(ray.BLACK);
        ray.EndDrawing();
    }
}
