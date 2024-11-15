const std = @import("std");
const sturcts = @import("0201_struct.zig");

pub fn SimpleArrayList(comptime T: type) type {
    return struct {
        const DefaultCapacity: usize = 10;
        const This = @This();
        allocator: std.mem.Allocator,
        items: []T,
        len: usize,

        pub fn init(allocator: std.mem.Allocator) !This {
            return .{
                .allocator = allocator,
                .items = try allocator.alloc(T, This.DefaultCapacity),
                .len = 0,
            };
        }

        pub fn enlarge(self: *This) !void {
            const new_capacity: usize = @intFromFloat(@as(f32, @floatFromInt(self.items.len)) * @as(f32, 1.5));
            const new_items = try self.allocator.alloc(T, new_capacity);
            std.mem.copyForwards(T, new_items, self.items);
            self.allocator.free(self.items);
            self.items = new_items;
        }

        pub fn append(self: *This, v: T) !void {
            if (self.len >= self.items.len) {
                try self.enlarge();
            }
            self.items[self.len] = v;
            self.len += 1;
        }

        pub fn insertNth(self: *This, n: usize, v: T) !void {
            if (n > self.len) {
                return error.IndexOutOfBound;
            }
            if (self.len >= self.items.len) {
                try self.enlarge();
            }
            var i = self.len;
            while (i >= n + 1) : (i -= 1) {
                self.items[i] = self.items[i - 1];
            }
            self.items[n] = v;
            self.len += 1;
        }

        pub fn nth(self: This, n: usize) !T {
            if (n >= self.len) {
                return error.IndexOutOfBound;
            }
            return self.items[n];
        }

        pub fn setNth(self: *This, n: usize, v: T) !void {
            if (n >= self.len) {
                return error.IndexOutOfBound;
            }
            self.items[n] = v;
        }

        pub fn deinit(self: This) void {
            self.allocator.free(self.items);
        }
    };
}

pub fn main() !void {
    sturcts.struct_main();
    var a = try SimpleArrayList(i8).init(std.heap.page_allocator);
    defer a.deinit();
    std.debug.print("{} of {}\n", .{ a.len, a.items.len });
    std.debug.print("{!}, {!}\n", .{ a.nth(10), a.setNth(10, 8) });
    try a.enlarge();
    std.debug.print("{} of {}\n", .{ a.len, a.items.len });
    for (0..17) |value| {
        try a.append(@as(i8, @intCast(value)));
    }
    std.debug.print("{} of {}\n", .{ a.len, a.items.len });
    try a.insertNth(2, -10);
    const a2th = a.nth(2);
    std.debug.print("Got {!}\n", .{a2th});
}
