const std = @import("std");
const ray = @import("raylib.zig");

const BLACK = ray.Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
const DARK_BLUE = ray.Color{ .r = 29, .g = 43, .b = 83, .a = 255 };
const DARK_PURPLE = ray.Color{ .r = 126, .g = 37, .b = 83, .a = 255 };
const DARK_GREEN = ray.Color{ .r = 0, .g = 135, .b = 81, .a = 255 };
const BROWN = ray.Color{ .r = 171, .g = 82, .b = 54, .a = 255 };
const DARK_GREY = ray.Color{ .r = 95, .g = 87, .b = 79, .a = 255 };
const LIGHT_GREY = ray.Color{ .r = 194, .g = 195, .b = 199, .a = 255 };
const WHITE = ray.Color{ .r = 255, .g = 241, .b = 232, .a = 255 };
const RED = ray.Color{ .r = 255, .g = 0, .b = 77, .a = 255 };
const ORANGE = ray.Color{ .r = 255, .g = 163, .b = 0, .a = 255 };
const YELLOW = ray.Color{ .r = 255, .g = 236, .b = 39, .a = 255 };
const GREEN = ray.Color{ .r = 0, .g = 228, .b = 54, .a = 255 };
const BLUE = ray.Color{ .r = 41, .g = 173, .b = 255, .a = 255 };
const LAVENDER = ray.Color{ .r = 131, .g = 118, .b = 156, .a = 255 };
const PINK = ray.Color{ .r = 255, .g = 119, .b = 168, .a = 255 };
const LIGHT_PEACH = ray.Color{ .r = 255, .g = 204, .b = 170, .a = 255 };

const Position = struct {
    x: f32,
    y: f32,
    fn squared_distance(self: *const Position, x: f32, y: f32) f32 {
        const x_dist = self.x - x;
        const y_dist = self.y - y;
        return x_dist * x_dist + y_dist * y_dist;
    }
};

const Circle = struct {
    center: Position,
    radius: f32,

    fn contains(self: *const Circle, x: f32, y: f32) bool {
        return (self.radius * self.radius) > self.center.squared_distance(x, y);
    }
};

fn render(x: f32, y: f32) ?ray.Color {
    const circle = Circle{ .center = Position{ .x = 10.0, .y = 20.0 }, .radius = 5.0 };
    if (circle.contains(x, y)) {
        return WHITE;
    }
    return null;
}

pub fn main() !void {
    ray.SetConfigFlags(ray.FLAG_WINDOW_RESIZABLE);
    ray.InitWindow(960, 540, "My Window Name");
    ray.SetTargetFPS(144);
    defer ray.CloseWindow();

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        ray.ClearBackground(DARK_GREY);

        const WIDTH_WORLD = 100.0;

        const width_screen: usize = @intCast(ray.GetScreenWidth());
        const height_screen: usize = @intCast(ray.GetScreenHeight());

        const HEIGHT_WORLD = WIDTH_WORLD * (@as(f32, @floatFromInt(height_screen)) / @as(f32, @floatFromInt(width_screen)));
        for (0..width_screen) |x_val| {
            const x: i32 = @intCast(x_val);
            const x_ratio: f32 = @as(f32, @floatFromInt(x_val)) / @as(f32, @floatFromInt(width_screen));
            for (0..height_screen) |y_val| {
                const y: i32 = @intCast(y_val);
                const y_ratio: f32 = @as(f32, @floatFromInt(y_val)) / @as(f32, @floatFromInt(height_screen));
                if (render(x_ratio * WIDTH_WORLD, (1.0 - y_ratio) * HEIGHT_WORLD)) |col| {
                    ray.DrawPixel(x, y, col);
                }
            }
        }

        ray.EndDrawing();
    }
}
