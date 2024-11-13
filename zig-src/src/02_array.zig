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

        pub fn deinit(self: This) void {
            self.allocator.free(self.items);
        }
    };
}

pub fn main() !void {
    sturcts.struct_main();
    const a = try SimpleArrayList(i8).init(std.heap.page_allocator);
    defer a.deinit();
    std.debug.print("{} of {}\n", .{ a.len, a.items.len });
}
