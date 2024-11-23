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

    fn scalar_mult(self: *const Position, scalar: f32) Position {
        return Position{ .x = self.x * scalar, .y = self.y * scalar };
    }

    fn magnitude_sqr(self: *const Position) f32 {
        return self.x * self.x + self.y * self.y;
    }

    fn dot(self: *const Position, other: Position) f32 {
        return self.x * other.x + self.y * other.y;
    }

    fn subtract_from(self: *const Position, other: Position) Position {
        return Position{ .x = other.x - self.x, .y = other.y - self.y };
    }
};

const Circle = struct {
    center: Position,
    radius: f32,

    fn contains(self: *const Circle, x: f32, y: f32) bool {
        return (self.radius * self.radius) > self.center.squared_distance(x, y);
    }
};

const Capsule = struct {
    root: Position,
    height: f32,
    radius: f32,
    angle: f32 = 0.0,

    fn contains(self: *const Capsule, x: f32, y: f32) bool {
        var pos = Position{ .x = x, .y = y };
        const anchor_direction = Position{ .x = self.height * std.math.cos(self.angle), .y = self.height * std.math.sin(self.angle) };
        var projected = anchor_direction.dot(self.root.subtract_from(pos)) / anchor_direction.magnitude_sqr();

        if (projected > 0.0) {
            if (projected > 1.0) {
                projected = 1.0;
            }
            pos = anchor_direction.scalar_mult(projected).subtract_from(pos);
        }
        return (self.radius * self.radius) > self.root.squared_distance(pos.x, pos.y);
    }
};

fn render(x: f32, y: f32, time: f32) ?ray.Color {
    const DEG_PER_SECOND = 180;
    const circle = Capsule{ .root = Position{ .x = 30.0, .y = 20.0 }, .radius = 5.0, .height = 10.0, .angle = @mod(time * DEG_PER_SECOND * std.math.pi / 180.0, 2 * std.math.pi) };
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
                const time: f32 = @floatCast(ray.GetTime());
                if (render(x_ratio * WIDTH_WORLD, (1.0 - y_ratio) * HEIGHT_WORLD, time)) |col| {
                    ray.DrawPixel(x, y, col);
                }
            }
        }

        ray.EndDrawing();
    }
}

test "capsule-angle-calculation" {
    const capsule = Capsule{ .root = Position{ .x = 0.0, .y = 0.0 }, .radius = 5.0, .height = 10.0, .angle = 0.5 * std.math.pi };

    try std.testing.expect(capsule.contains(0.0, 0.0));
    try std.testing.expect(capsule.contains(0.5 * capsule.height * std.math.cos(capsule.angle), 0.5 * capsule.height * std.math.sin(capsule.angle)));
    try std.testing.expect(capsule.contains(capsule.height * std.math.cos(capsule.angle), capsule.height * std.math.sin(capsule.angle)));
}
