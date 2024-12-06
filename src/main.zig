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

    fn add(self: *Position, other: Position) void {
        self.x += other.x;
        self.y += other.y;
    }
};

const World = struct {
    player_pos: Position,
    player_faces_right: bool = true,
    player_movement_speed: Position = Position{ .x = 0.0, .y = 0.0 },
    fn update(self: *World, dt: f32) void {
        const FALLING_SPEED = 30;
        const MOVEMENT_SPEED = 20;
        // Simulate falling
        if (self.player_pos.y > 0.0) {
            self.player_movement_speed.y -= FALLING_SPEED * dt;
        } else if (ray.IsKeyPressed(ray.KEY_SPACE)) {
            // On the ground and jumping
            const JUMPING_SPEED = 7;
            self.player_movement_speed.y += JUMPING_SPEED;
        }

        self.player_movement_speed.x = 0.0;
        if (ray.IsKeyDown(ray.KEY_A) or ray.IsKeyDown(ray.KEY_LEFT)) {
            self.player_movement_speed.x = -dt * MOVEMENT_SPEED;
            self.player_faces_right = false;
        } else if (ray.IsKeyDown(ray.KEY_S) or ray.IsKeyDown(ray.KEY_RIGHT)) {
            self.player_movement_speed.x = dt * MOVEMENT_SPEED;
            self.player_faces_right = true;
        }
        self.player_pos.add(self.player_movement_speed);
        if (self.player_pos.y < 0.0) {
            self.player_pos.y = 0.0;
            self.player_movement_speed.y = 0.0;
        }
    }

    fn render_pixel(self: *const World, x: f32, y: f32) ?ray.Color {
        if (render_character(self.player_pos, x, y, !self.player_faces_right)) {
            return WHITE;
        }
        return null;
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

    fn anchor(self: *const Capsule) Position {
        return Position{ .x = self.root.x + self.height * std.math.cos(self.angle), .y = self.root.y + self.height * std.math.sin(self.angle) };
    }

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

fn angle_base(base: f32, invert: bool) f32 {
    if (invert) {
        return 1 - base;
    }
    return base;
}

fn render_character(pos: Position, x: f32, y: f32, invert: bool) bool {
    // TODO: Replace all these magic numbers by named constans
    const height = 20.0;
    const body = Capsule{ .root = Position{ .x = pos.x, .y = pos.y + 0.5 * height }, .radius = 1.0, .height = 0.5 * height, .angle = 0.5 * std.math.pi };
    const head = Circle{ .center = Position{ .x = pos.x, .y = pos.y + height }, .radius = 3.0 };

    const left_upper_arm = Capsule{ .root = Position{ .x = pos.x, .y = pos.y + 0.7 * height }, .radius = 0.5, .height = 5, .angle = angle_base(-0.25, invert) * std.math.pi };
    const left_lower_arm = Capsule{ .root = left_upper_arm.anchor(), .radius = 0.5, .height = 5, .angle = angle_base(0.25, invert) * std.math.pi };

    const right_upper_arm = Capsule{ .root = Position{ .x = pos.x, .y = pos.y + 0.7 * height }, .radius = 0.5, .height = 5, .angle = angle_base(1.25, invert) * std.math.pi };
    const right_lower_arm = Capsule{ .root = right_upper_arm.anchor(), .radius = 0.5, .height = 5, .angle = angle_base(1.75, invert) * std.math.pi };

    const left_upper_leg = Capsule{ .root = Position{ .x = pos.x, .y = pos.y + 0.5 * height }, .radius = 0.5, .height = 5, .angle = angle_base(-0.35, invert) * std.math.pi };
    const left_lower_leg = Capsule{ .root = left_upper_leg.anchor(), .radius = 0.5, .height = 5, .angle = angle_base(1.5, invert) * std.math.pi };

    const right_upper_leg = Capsule{ .root = Position{ .x = pos.x, .y = pos.y + 0.5 * height }, .radius = 0.5, .height = 5, .angle = angle_base(1.5, invert) * std.math.pi };
    const right_lower_leg = Capsule{ .root = right_upper_leg.anchor(), .radius = 0.5, .height = 5, .angle = angle_base(1.35, invert) * std.math.pi };

    return body.contains(x, y) or
        head.contains(x, y) or
        left_upper_arm.contains(x, y) or
        left_lower_arm.contains(x, y) or
        right_upper_arm.contains(x, y) or
        right_lower_arm.contains(x, y) or
        left_upper_leg.contains(x, y) or
        left_lower_leg.contains(x, y) or
        right_upper_leg.contains(x, y) or
        right_lower_leg.contains(x, y);
}

fn render_world(world: *const World, screen_width: usize, screen_height: usize) void {
    const VIRTUAL_PIXEL_SIZE = 5;

    const WORLD_WIDTH = 100;
    const screen_ratio = @as(f32, @floatFromInt(screen_height)) / @as(f32, @floatFromInt(screen_width));
    const WORLD_HEIGHT = WORLD_WIDTH * screen_ratio;

    for (0..(screen_width / VIRTUAL_PIXEL_SIZE)) |x_val| {
        const x: i32 = @intCast(x_val);
        const x_ratio = @as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(screen_width / VIRTUAL_PIXEL_SIZE));
        for (0..(screen_height / VIRTUAL_PIXEL_SIZE)) |y_val| {
            const y: i32 = @intCast(y_val);
            const y_ratio: f32 = @as(f32, @floatFromInt(y_val)) / @as(f32, @floatFromInt(screen_height / VIRTUAL_PIXEL_SIZE));
            if (world.render_pixel(x_ratio * WORLD_WIDTH, (1.0 - y_ratio) * WORLD_HEIGHT)) |col| {
                for (0..VIRTUAL_PIXEL_SIZE) |dx| {
                    for (0..VIRTUAL_PIXEL_SIZE) |dy| {
                        ray.DrawPixel(x * VIRTUAL_PIXEL_SIZE + @as(i32, @intCast(dx)), y * VIRTUAL_PIXEL_SIZE + @as(i32, @intCast(dy)), col);
                    }
                }
            }
        }
    }
}

pub fn main() !void {
    ray.SetConfigFlags(ray.FLAG_WINDOW_RESIZABLE);
    ray.InitWindow(960, 540, "My Window Name");
    ray.SetTargetFPS(144);
    defer ray.CloseWindow();

    const player_pos = Position{ .x = 30.0, .y = 20.0 };
    var world = World{ .player_pos = player_pos };

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        ray.ClearBackground(DARK_GREY);

        world.update(@floatCast(ray.GetFrameTime()));

        render_world(&world, @intCast(ray.GetScreenWidth()), @intCast(ray.GetScreenHeight()));

        ray.EndDrawing();
    }
}

test "capsule-angle-calculation" {
    const capsule = Capsule{ .root = Position{ .x = 0.0, .y = 0.0 }, .radius = 5.0, .height = 10.0, .angle = 0.5 * std.math.pi };

    try std.testing.expect(capsule.contains(0.0, 0.0));
    try std.testing.expect(capsule.contains(0.5 * capsule.height * std.math.cos(capsule.angle), 0.5 * capsule.height * std.math.sin(capsule.angle)));
    try std.testing.expect(capsule.contains(capsule.height * std.math.cos(capsule.angle), capsule.height * std.math.sin(capsule.angle)));
}
