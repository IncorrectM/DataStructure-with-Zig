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
        root: ?*Node,

        pub fn init(root: T, allocator: std.mem.Allocator) !This {
            const root_node = try allocator.create(Node);
            root_node.* = Node.init(root);
            return .{
                .allocator = allocator,
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

test "init and deinit" {
    const allocator = std.testing.allocator;
    var tree = BinarySearchTree(i32).init(0, allocator) catch |e| {
        std.debug.print("{}\n", .{e});
        return error.OOM;
    };
    defer tree.deinit();
}
