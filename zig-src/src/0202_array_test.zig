const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const array = @import("02_array.zig"); // 我们实现的SimpleArrayList保存在这个文件中

test "test append" {
    // 我们使用std.testing.allocator
    // 这个分配器适合不需要分配大块内存的测试场景
    // 它可以帮助我们检测潜藏的内存泄漏
    const allocator = std.testing.allocator;
    var list = try array.SimpleArrayList(u32).init(allocator);
    // 注释下面这一行，zig test会自动检查到内存泄漏
    defer list.deinit();
    // 插入17个数字
    for (0..17) |value| {
        // value是usize类型的，这个类型在我的电脑上是u64，大于u32，所以u64转换为u32是不安全的
        // zig不会自动进行不安全的类型转换
        // 所以我们需要手动转换数据类型
        try list.append(@as(u32, @intCast(value)));
    }
    // 真实值
    const actual = [17]u32{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    // 插入17个数字后，长度应该为17
    try expect(list.len == 17);
    // 插入17个数字，会触发两次扩容，list.items.len应该为22
    try expect(list.items.len == 22);
    // std.mem.eql可以对比两个数组/切片（slice）是否相同
    try expect(std.mem.eql(u32, list.items[0..17], &actual));
}
