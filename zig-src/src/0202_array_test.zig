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
    const expected = [17]u32{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    // 插入17个数字后，长度应该为17
    try expect(list.len == 17);
    // 插入17个数字，会触发两次扩容，list.items.len应该为22
    try expect(list.items.len == 22);
    // std.mem.eql可以对比两个数组/切片（slice）是否相同
    try expect(std.mem.eql(u32, list.items[0..17], &expected));
}

test "test nth" {
    // 初始化
    const allocator = std.testing.allocator;
    var list = try array.SimpleArrayList(u32).init(allocator);
    defer list.deinit();
    // 准备数据
    for (0..17) |value| {
        try list.append(@as(u32, @intCast(value)));
    }
    // 测试正常获取前17个元素
    for (0..17) |index| {
        const expected: u32 = @intCast(index);
        const actual = try list.nth(index);
        try expect(expected == actual);
    }
    // 测试超出范围
    try expectError(error.IndexOutOfBound, list.nth(1000));
}

test "test setNth" {
    // 初始化
    const allocator = std.testing.allocator;
    var list = try array.SimpleArrayList(u32).init(allocator);
    defer list.deinit();

    // 设置空的列表视为越界
    try expectError(error.IndexOutOfBound, list.setNth(0, 1));

    // 准备数据
    for (0..17) |value| {
        try list.append(@as(u32, @intCast(value)));
    }
    // 设置某个元素为1000，并判断取出的数值是否为1000
    try list.setNth(6, 1000);
    const actual = try list.nth(6);
    try expect(actual == 1000);

    // 还要检查前后的数据是否正常
    const expected = [17]u32{ 0, 1, 2, 3, 4, 5, 1000, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    try expect(std.mem.eql(u32, list.items[0..17], &expected));

    // 测试越界
    try expectError(error.IndexOutOfBound, list.setNth(1000, 1));
}

test "test insertNth" {
    // 初始化
    const allocator = std.testing.allocator;
    var list = try array.SimpleArrayList(u32).init(allocator);
    defer list.deinit();

    // 设置空的列表的第一个视为append
    try list.insertNth(0, 0);
    try expect((try list.nth(0)) == 0);

    // 准备数据
    for (1..17) |value| {
        try list.append(@as(u32, @intCast(value)));
    }
    // 在某个位置插入1000，并判断取出的数值是否为1000
    try list.insertNth(6, 1000);
    const actual = try list.nth(6);
    try expect(actual == 1000);

    // 还要检查前后的数据是否正常
    const expected = [18]u32{ 0, 1, 2, 3, 4, 5, 1000, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    try expect(std.mem.eql(u32, list.items[0..18], &expected));

    // 测试越界
    try expectError(error.IndexOutOfBound, list.insertNth(1000, 1));
}

test "test removeNth" {
    // 初始化
    const allocator = std.testing.allocator;
    var list = try array.SimpleArrayList(u32).init(allocator);
    defer list.deinit();

    // 准备数据
    for (0..17) |value| {
        try list.append(@as(u32, @intCast(value)));
    }

    // 删除一个数据，然后判断是否正确删除
    const removed = try list.removeNth(0);
    try expect(removed == 0);
    try expect((try list.nth(0)) != 0);

    // 还要检查前后的数据是否正常
    const expected = [16]u32{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    try expect(std.mem.eql(u32, list.items[0..16], &expected));

    // 测试越界
    try expectError(error.IndexOutOfBound, list.removeNth(1000));
}
