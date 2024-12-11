const std = @import("std");

pub fn BinarySearchTreeNode(T: type) type {
    return struct {
        const This = @This();
        data: T,
        left: ?*This,
        right: ?*This,

        pub fn init(data: T) This {
            return .{
                .data = data,
                .left = null,
                .right = null,
            };
        }

        pub fn deinit(self: *This) void {
            if (self.left != null) {
                self.left.?.deinit();
            }
            if (self.right != null) {
                self.right.?.deinit();
            }
            // TODO: self.data.deinit
        }
    };
}

pub fn BinarySearchTree(T: type) type {
    return struct {
        const This = @This();
        const Node = BinarySearchTreeNode(T);
        allocator: std.mem.Allocator,
        comparator: *const fn (T, T) i2,
        root: ?*Node,

        pub fn init(root: T, comparator: *const fn (T, T) i2, allocator: std.mem.Allocator) !This {
            const root_node = try allocator.create(Node);
            root_node.* = Node.init(root);
            return .{
                .allocator = allocator,
                .comparator = comparator,
                .root = root_node,
            };
        }

        pub fn deinit(self: *This) void {
            if (self.root != null) {
                self.root.?.deinit();
                self.allocator.destroy(self.root.?);
            }
        }
    };
}

pub fn comparei32(a: i32, b: i32) i2 {
    if (a > b) {
        return 1;
    } else if (a < b) {
        return -1;
    }
    return 0;
}

test "init and deinit" {
    const allocator = std.testing.allocator;
    var tree = BinarySearchTree(i32).init(0, &comparei32, allocator) catch |e| {
        std.debug.print("{}\n", .{e});
        return error.OOM;
    };
    defer tree.deinit();
}
