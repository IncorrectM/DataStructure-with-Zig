# Stack 栈

栈同样是一种线性结构，它只允许在末尾进行操作，并且遵循“先进后出”的原则。

举个例子，堆在桌子上的一叠书可以看作一个栈。放书时，只能放在最上面（末尾），拿书时也只能拿最上面那本（末尾最后一个元素）。要拿出最底下的书，必须从最顶上的书开始一本一本拿下来，这就是“先进先出”。

本章中，我们将借助第二章中实现的列表`SimpleArrayList`来实现栈。尽管如此，我还是不建议将本书中实现的程序用在实践中。

## 准备工作

在正式开始介绍和实现基本操作前，让我们先实现一些基础的函数和方法。

```zig
pub fn Stack(T: type) type {
    return struct {
        const This = @This();
        const List = ArrayList(T);
        allocator: std.mem.Allocator,
        data: This.List,

        pub fn init(allocator: std.mem.Allocator) !This {
            return .{
                .allocator = allocator,
                .data = try This.List.init(allocator),
            };
        }

        pub fn top(self: This) usize {
            return self.data.len;
        }

        pub fn isEmpty(self: This) bool {
            return self.top() == 0;
        }

        pub fn deinit(self: *This) void {
            self.data.deinit();
        }
    };
}
```

首先，我们保存了This和List两个类型，来方便我们的后续使用。通过保存List，在有需要的时候，我们可以方便地把List的值修改为其他值，而不用修改代码中其他出现List的地方。当然，在我们简单的实现中，这并不是必要的。

随后，我们保存了一个allocator，并用这个allocator初始化了一个列表的示例用来保存数据。

然后，我们创建了初始化函数init和反初始化方法deinit，这个和前面的没有差别。

最后，我们创建了`top`方法和`isEmpty`方法。`top`方法返回下一个进入到栈中（入栈）的元素应该被保存到哪，而`isEmpty`方法判断栈是不是为空。我们将会进场用到这两个方法，把它们作为单独的方法可以让我们的程序更加清晰，也更加便于修改。

## 基本操作

栈并不复杂，它有下面的主要方法：

1. push：入栈一个元素；
2. pop：返回最后一个元素，并从栈中移除这个元素；
3. peek：返回最后一个元素，但不移除；

借助于先前实现的SimpleArrayList，我们可以不用手动管理内存了！

我们一个一个来。

### push

看着`push`的功能，你有没有觉得眼熟？没错，列表的`append`和它有着几乎一样的功能。因此，我们的实现只是简单的在`append`之外套了一层。

```zig
pub fn push(self: *This, v: T) !void {
    try self.data.append(v);
}
```

### pop

记得第二章的挑战吗？如果你完成了挑战，那么这里的`pop`可以直接使用之前实现的pop。

如果没有，其实也很简单：通过nth获得最后一个元素，在通过removeNth删除这个元素就行。因为我们删除的是最后一个元素，所以也可以不用removeNth，直接长度减一就行。

于是，我们有下面的实现：

```zig
pub fn pop(self: *This) ?T {
    if (self.isEmpty()) {
        // 空栈
        return null;
    }
    const lastIndex = self.top() - 1;
    //                                      👇 看这里 👇
    const last = self.data.nth(lastIndex) catch unreachable;
    // 使用函数进行修改
    // self.data.removeNth(lastIndex);
    // 或者手动修改
    self.data.len -= 1;
    return last;
}
```

注意看，我们又遇到了没见过的东西！

让我们回顾前面实现的`SimpleArrayList`，我们会发现`nth`函数返回的是一个错误联合类型，必须要处理错误才能拿到实际的值。

在以前的实现中，我们通过`try`关键字处理错误——遇到错误时返回错误，否则获得具体值。`catch`也是用来处理错误的，我们用一个简单的例子来说明：

```zig
const std = @import("std");

pub fn errorIfZero(v: i32) !i32 {
    if (v == 0) {
        return error.Zero;
    } else {
        return v;
    }
}

pub fn main() !void {
    _ = errorIfZero(10086) catch {
        std.debug.print("I will not be printed.\n", .{});
    };

    _ = errorIfZero(0) catch {
        std.debug.print("I will be printed since you passed 0.\n", .{});
    };

    _ = errorIfZero(0) catch |err| {
        std.debug.print("Caught an error {!}\n", .{err});
    };
}
```

```ansi
$stdout returns nothing.
$stderr:
I will be printed since you passed 0.
Caught an error error.Zero
```

我们定义了一个函数，在传入0时返回错误，否则返回传入的数字。

第一个`catch`后面的语句不会被调用，因为`errorIfZero(10086)`会返回10086；第二个`catch`后面的语句会被调用，因为`errorIfZero(0)`会返回错误error.Zero；而在第三个`catch`后面的语句中，我们捕获了返回的错误，并且打印了错误的值。

通过`catch`关键字，我们能更加灵活的处理错误联合类型。

### peek

## 测试

### push

我们要保证数据正确地入栈，并且没有影响前面的数据。我们可以通过直接方位`data`成员内部的`items`成员来做出判断。

```zig
test "test push" {
    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    const actual = [_]i32{ 1, 3, 4, 9, 1, 0, 111, 19928, 31415, 8008820 };
    for (actual) |value| {
        try stack.push(value);
        // 测试元素是否正确地入栈
        try expect(stack.top() != 0);
        try expect(stack.data.items[stack.top() - 1] == value);
    }
    try expect(std.mem.eql(i32, &actual, stack.data.items));
}
```

### pop

我们可以准备一组数据，将它们按顺序入栈。然后将它们的顺序翻转过来，再逐个出栈，确保实现了“先进后出”。最后，我们再试试弹出空栈能不能返回空值。

```zig
test "test pop" {
    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    var actual = [_]i32{ 1, 3, 4, 9, 1, 0, 111, 19928, 31415, 8008820 };
    for (actual) |value| {
        try stack.push(value);
    }

    // 出栈应该是先进后出
    std.mem.reverse(i32, &actual);
    // 一个个出栈并检查是否符合预期
    for (actual) |value| {
        const poped = stack.pop();
        try expect(poped != null and poped.? == value);
    }

    // 试图弹出空栈会返回空值
    try expect(stack.pop() == null);
}
```

### peek

## 应用示例 - 括号匹配

## 挑战

## 完整代码

🚧施工中🚧

