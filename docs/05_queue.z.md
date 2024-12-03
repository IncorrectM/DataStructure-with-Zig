# Queue 队列

队列也是一种线性结构，它遵循“先进先出”的原则，就和我们日常生活中排队一样。

因为我们需要频繁的在队列的头部移除元素，并在队列的尾部添加元素，如果使用连续存储的列表的话或产生频繁的元素移动，所以使用链表比较合适。
本章中，我们将借助第三章中实现的`LinkedList`来实现队列。

## 准备工作

在正式开始介绍和实现基本操作前，让我们先实现一些基础的函数和方法。

```zig -skip
pub fn Queue(T: type) type {
    return struct {
        const This = @This();
        const List = LinkedList(T);
        allocator: std.mem.Allocator,
        data: This.List,

        pub fn init(allocator: std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .data = This.List.init(allocator),
            };
        }

        pub fn deinit(self: *This) void {
            self.data.deinit();
        }
    };
}
```

和在栈中一样，我们保存了This和List两个类型来方便开发，并保存了allocator和data用于存储数据。

## 基本操作

队列的方法并不复杂，最主要的操作只有两个：入队和出队。

1. enqueue：入队，也就是添加一个元素到队列末尾；
2. dequeue：出队，也就是移除队列头部的元素。

感谢我们的链表，这两个函数可以分别通过`append`和`popFirst`来实现，这就让我们的实现简单了很多：

```zig -skip
pub fn enqueue(self: *This, v: T) !void {
    _ = try self.data.append(v);
}
pub fn dequeue(self: *This) ?T {
    const node = self.data.popFirst();
    if (node) |n| {
        const result = n.data;
        self.allocator.destroy(n);
        return result;
    }
    return null;
}
```

基本上我们只是调用了链表里的方法而已。不过我还是对返回值做了一点处理的——我们不会把链表的节点暴露给队列的用户。

首先，是入队方法。我们拦截了正常插入时的返回值，但是向用户返回可能的错误。

其次，是出队方法。我们只把离开链表的节点的值返回给用户。记得吗？在第三章中我们说过，这个方法会把节点对应的内存的管理权交给调用者。通过只返回值，我们可以避免再一次把管理权传递给下一个调用者，然后在这里就地释放这块内存。如果你在链表中实现的`popFirst`没有交出管理权，那这里就不需要这么复杂了。

::: tip
事实上，编译器也不允许我们把节点暴露出去。

尝试把`enqueue`的返回值改为`!*List.Node`，然后再运行测试代码，看看你会得到什么。

编译器会提示你，这个成员不是公开的，错误提示类似于下面这样：

```ansi
src/05_queue.zig:19:48: error: 'Node' is not marked 'pub'
        pub fn enqueue(self: *This, v: T) !*List.Node {
                                           ~~~~^~~~~
src/03_linked_list.zig:32:9: note: declared here
        const Node = LinkedListNode(T);
        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

这是因为，我们在`LinkedList`中声明成员`Node`时，并没有说明它是公开的。像解决这个问题，只用把

```zig -skip
const Node = LinkedListNode(T);
```

改为

```zig -skip
pub const Node = LinkedListNode(T);
```

即可。
:::

我们可以测试了。

## 测试

```zig -test_collect_1
const std = @import("std");
const Queue = @import("lib/05_queue.zig").Queue;
const expect = std.testing.expect;
```

```zig -test_1
test "test enqueue" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    const expected = [_]i32{ 1, 88, 43, 0, -10, 100 };
    for (expected) |value| {
        try queue.enqueue(value);
    }

    // 我们借助链表的方法来检查元素
    for (0..expected.len) |value| {
        const first = queue.data.popFirst();
        try expect(first != null);
        try expect(first.?.data == expected[value]);
        allocator.destroy(first.?); // 在LinkedList的实现中我们提到过，这个方法会把节点的内存管理权交给使用者
    }

    const empty = queue.data.popFirst();
    try expect(empty == null);
}

test "test dequeue" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    const expected = [_]i32{ 1, 88, 43, 0, -10, 100 };
    for (expected) |value| {
        // 我们借助链表的方法来插入元素
        _ = try queue.data.append(value);
    }

    for (0..expected.len) |value| {
        const first = queue.dequeue();
        try expect(first != null);
        try expect(first.? == expected[value]);
    }

    const empty = queue.dequeue();
    try expect(empty == null);
}

test "use enqueu and dequeue together" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    const expected = [_]i32{ 1, 88, 43, 0, -10, 100 };
    for (expected) |value| {
        try queue.enqueue(value);
    }

    for (0..expected.len) |value| {
        const first = queue.dequeue();
        try expect(first != null);
        try expect(first.? == expected[value]);
    }

    const empty = queue.dequeue();
    try expect(empty == null);
}
```

这里的测试没有什么可过多介绍的。

## 应用示例

## 挑战 —— 双向队列

双向链表是链表的变体，它允许在队列的头部进入队列，也允许从队列的末尾离开队列。在链表的基础上，它还多了两个方法：

1. dequeueLast：队列末尾出队；
2. enqueueFirst：队列头部入队；

来试试实现他们它们。

## 完整代码

::: details 05_queue.zig
```zig -skip
const std = @import("std");

const LinkedList = @import("03_linked_list.zig").LinkedList;

pub fn Queue(T: type) type {
    return struct {
        const This = @This();
        const List = LinkedList(T);
        allocator: std.mem.Allocator,
        data: This.List,

        pub fn init(allocator: std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .data = This.List.init(allocator),
            };
        }

        pub fn enqueue(self: *This, v: T) !void {
            _ = try self.data.append(v);
        }

        pub fn dequeue(self: *This) ?T {
            const node = self.data.popFirst();
            if (node) |n| {
                const result = n.data;
                self.allocator.destroy(n);
                return result;
            }
            return null;
        }

        pub fn deinit(self: *This) void {
            self.data.deinit();
        }
    };
}
```
:::

::: details 0502_queue_test.zig
```zig -skip
const std = @import("std");
const Queue = @import("05_queue.zig").Queue;
const expect = std.testing.expect;

test "test enqueue" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    const expected = [_]i32{ 1, 88, 43, 0, -10, 100 };
    for (expected) |value| {
        try queue.enqueue(value);
    }

    // 我们借助链表的方法来检查元素
    for (0..expected.len) |value| {
        const first = queue.data.popFirst();
        try expect(first != null);
        try expect(first.?.data == expected[value]);
        allocator.destroy(first.?); // 在LinkedList的实现中我们提到过，这个方法会把节点的内存管理权交给使用者
    }

    const empty = queue.data.popFirst();
    try expect(empty == null);
}

test "test dequeue" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    const expected = [_]i32{ 1, 88, 43, 0, -10, 100 };
    for (expected) |value| {
        // 我们借助链表的方法来插入元素
        _ = try queue.data.append(value);
    }

    for (0..expected.len) |value| {
        const first = queue.dequeue();
        try expect(first != null);
        try expect(first.? == expected[value]);
    }

    const empty = queue.dequeue();
    try expect(empty == null);
}

test "use enqueu and dequeue together" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    const expected = [_]i32{ 1, 88, 43, 0, -10, 100 };
    for (expected) |value| {
        try queue.enqueue(value);
    }

    for (0..expected.len) |value| {
        const first = queue.dequeue();
        try expect(first != null);
        try expect(first.? == expected[value]);
    }

    const empty = queue.dequeue();
    try expect(empty == null);
}
```
:::

🚧施工中🚧
