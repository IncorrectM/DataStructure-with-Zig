const std = @import("std");
const LinkedList = @import("03_linked_list.zig").LinkedList;

/// 计算给定字符串的 djb2 哈希值。
///
/// djb2 是一种非加密哈希函数，常用于哈希表等数据结构中。它由 Dan J. Bernstein 提出，
/// 以其计算速度快和冲突率低而著称。该算法通过将每个字符左移5位然后加上原字符的 ASCII 值，
/// 并与之前的哈希值相加来生成最终的哈希值。
///
/// @param str 被哈希的字符串。
/// @return
///   - 返回一个无符号整数作为字符串的哈希值。
///
pub fn djb2(str: []const u8) usize {
    var hash: usize = 5381;

    for (str) |c| {
        // 直接对C进行左移5位的操作可能会超出u8的表示范围，
        //    因此需要显式地转换为更大的数据类型
        const larger_c: usize = @intCast(c);
        hash += (larger_c << 5) + larger_c;
    }

    return hash;
}

pub fn HashTable(K: type, V: type) type {
    return struct {
        const This = @This();
        const List = LinkedList(V);
        allocator: std.mem.Allocator,
        hash_func: *const fn (K) usize,
        key_accessor: *const fn (V) K,
        key_euqal: *const fn (K, K) bool,
        lists: []List,

        pub fn init(
            allocator: std.mem.Allocator,
            hash_func: *const fn (K) usize,
            key_accessor: *const fn (V) K,
            key_euqal: *const fn (K, K) bool,
            data_length: usize,
        ) !This {
            var lists = try allocator.alloc(List, data_length);
            for (0..lists.len) |i| {
                lists[i] = List.init(allocator);
            }
            return .{
                .allocator = allocator,
                .lists = lists,
                .hash_func = hash_func,
                .key_accessor = key_accessor,
                .key_euqal = key_euqal,
            };
        }

        pub fn put(self: *This, value: V) !void {
            const key = self.key_accessor(value);
            const hash = self.hash_func(key) % self.lists.len; // 哈希值可能会很大，通过取余的方式避免越界
            _ = try self.lists[hash].append(value);
        }

        pub fn get(self: *This, key: K) ?V {
            const hash = self.hash_func(key) % self.lists.len;
            const list = self.lists[hash];

            var cur = list.head;
            // 逐个节点查找
            while (cur) |c| {
                if (self.key_euqal(self.key_accessor(c.*.data), key)) {
                    return c.data;
                }
                cur = c.next;
            }
            return null;
        }

        pub fn remove(self: *This, key: K) void {
            const hash = self.hash_func(key) % self.lists.len;
            const list = &self.lists[hash];

            var cur = list.head;
            // 逐个节点查找
            while (cur) |c| {
                if (self.key_euqal(self.key_accessor(c.*.data), key)) {
                    break;
                }
                cur = c.next;
            }
            // 删除找到的节点
            if (cur) |c| {
                list.remove(c);
            }
        }

        pub fn deinit(self: *This) void {
            for (0..self.lists.len) |i| {
                self.lists[i].deinit();
            }
            self.allocator.free(self.lists);
        }
    };
}

pub fn main() void {
    std.debug.print("Hello HashTable!\n", .{});
    std.debug.print("DJB2 of 'Hello HashTable!' is {}.\n", .{djb2("Hello HashTable!")});
}
