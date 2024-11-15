# ArrayList 列表

## 内存是一种资源

Zig不会代替程序员管理内存，因此，使用Zig进行编程的人必须知道怎么管理内存。

当然，就我们的主题而言，你并不需要非常熟悉怎么进行管理，我们也不会在这方面深入太多。

在这里，我们只介绍一种简单的内存管理方式，有关内存的详细可见[这个网站](https://ziglang.org/documentation/master/#Memory)。

### ArenaAllocator

在本书中，我们实现的数据结构并不会被投入到实际的生产开发中（我不建议这么做），所有的数据结构的实例都只会存在很短的一段时间，因此，完全可以使用ArenaAllocator来分配内存。这样，我们可以一次性施放申请的所有内存。如果你想知道ArenaAllocator是怎么工作的，可以查看[这个网站](https://www.huy.rocks/everyday/01-12-2022-zig-how-arenaallocator-works)。

让我们来分配点东西吧！

```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();
const a_number = try allocator.create(u32);
a_number.* = 100;
std.debug.print("We allocated {p} which stores {d}!\n", .{ a_number, a_number.* });
arena.deinit();
```

```ansi
$stdout returns nothing.
$stderr:
We allocated u32@151ed1796010 which stores 100!
```

让我们来逐行看看有什么吧！

1. `var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);`：通过传入一个其他的Allocator，我们初始化了一个ArenaAllocator。ArenaAllocator会用这个分配器来实际分配内存；
2. `const allocator = arena.allocator();`：我们从arena中要了一个Allocator，这是我们用它来分配内存；
3. `const a_number = try allocator.create(u32);`：我们从内存中要来了一块能放下u32类型的空间，create函数返回的是一个错误联合类型，通过try我们拿出了实际的值——一个指向分配的内存区域的指针。如果你忘了错误联合类型，可以看看[上一章](./01_zig_basics)。
4. `a_number.* = 100;`：我们向刚才分配的内存写了100这个数字；
5. `std.debug.print("We allocated {p} which stores {d}!\n", .{ a_number, a_number.* });`： 打印它！
6. `arena.deinit();`：当我们不再使用arena后，一定要反初始化（deinit）它，来施放所有的内存。

在后面的章节中，我们将经常见到类似的片段。

## 结构体

为了实现一种数据结构，我们需要一个地方存储数据，在这里我们有“结构”。

如果你有使用C的经验，你应该对下面的代码不会陌生：

```zig
const Point = struct {
    // 结构体
    x: f32, // 成员
    y: f32, // 成员
};
```

如果你觉得陌生也没关系，我们慢慢解释。

首先，在`const Point = struc {};`这里我们声明了一个名为Point的变量，并为其赋值为一个结构体。在Zig中，类型是“一等公民”，它可以像值、指针一样被赋予变量。

在两个花括号之间的部分，被称为结构体。在结构体内可以声明这个结构的成员。在这里，我们声明了两个类型为f32的成员——x和y。

有了结构体，我们可以把它用起来。

```zig {3}
const std = @import("std");
pub fn main() void {
    const point = Point{
        .x = 1.0,
        .y = 1.80086,
    };

    std.debug.print("We got a point ({}, {}).\n", .{ point.x, point.y });
}
```

```ansi
$stdout returns nothing.
$stderr:
We got a point (1e0, 1.80086e0).
```

有两个点需要解释一下。

首先，在第3行，我们声明了一个point变量，然后初始化了一个Point结构并赋值给它。初始化语句也和C里面非常相似。

其次，我们打印了point里存储的值。这里的`point.x`和`point.y`分别访问了两个成员，`.`叫作成员访问运算符。

## 数组

数组（Array）是一种线性数据结构，它由相同类型的数据元素组成，这些元素存储在连续的区域内，并且可以通过下标进行访问。

下面的图片是一个数组示例，这个数组中存储了5个类型为i8的整型数字，因此长度为5。同时，箭头指向了第一个元素，这个元素的下标是0。

![数组示例](./imgs/02/0201_Array.png)

我们已经见过在Zig怎么创建和访问一样的数组：

```zig
const number = [5]i8{ 2, -1, 5, 6, 3 };
for (number, 0..) |value, i| {
    std.debug.print("Index={}, Value={}\n", .{ i, value });
}
std.debug.print("number.len={}\n", .{number.len});
```

```ansi
$stdout returns nothing.
$stderr:
Index=0, Value=2
Index=1, Value=-1
Index=2, Value=5
Index=3, Value=6
Index=4, Value=3
number.len=5
```

在大多数编程语言中，数组的长度都是固定的，必须要编译的时候就确定长度。

## 变长的数组 —— 列表

如果我们想要动态地调整数组长度呢？在Python中，常用的列表可以自动调整长度；在Rust中，我们可以使用向量Vec。在这里，我们使用**列表**这个称呼，将我们实现的版本命名为SimpleArrayList。

::: tip
Zig语言的标准库提供了一个列表的实现[std.ArrayList](https://ziglang.org/documentation/master/std/#std.ArrayList)，我们跟随标准库称之为列表（List）。
:::

正如其名，SimpleArrayList使用普通的数组存储数据。同时，我们需要知道存储了多少个元素，并且需要能在需要时扩大内部存储用的数组。由此，我们可以得到下面的基本的定义：

```zig
const SimpleArrayList = struct {
    allocator: std.mem.Allocator,   // 内存分配器，用于动态分配内存
    items: []???,                  // 列表内元素
    len: usize,                     // 列表内元素的数量
};
```

### 实现**泛型**

这里还有一个问题，`items`应该是什么类型的呢？为了能使列表适用于不同类型的数据，我们需要**泛型**。简单来说，泛型就是通过某种方式，使得函数或是结构体可以接收不同的类型作为参数或成员。

我们前面说过，在Zig中类型是一等公民，这意味着我们可以将类型作为参数传给函数，也可以作为返回值返回。我们可以通过这种方式实现泛型。我们可以声明一个函数，接收一个类型T，然后返回存储类型T的元素的列表。

```zig
pub fn SimpleArrayList(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        items: []T,
        len: usize,
    };
}
```

在这里，我们遇到了几个没见过的东西：

1. 关键词`comptime`：这是Zig的一个重要属性，它有很多用处，在这里，它意味着T是一个在编译的时候就已知的值；
2. 类型`type`：这个类型是“类型的类型”；

通过这种方式返回的结构体的名字比较复杂，不方便使用，我们可以用Zig的内建函数来构建一个别名来。

```zig {3}
pub fn SimpleArrayList(comptime T: type) type {
    return struct {
        const This = @This();
        allocator: std.mem.Allocator,
        items: []T,
        len: usize,
    };
}
```

在第3行中，我们使用`@This()`函数获得了当前结构的类型。

::: tip
在所有内建函数中，以大写字母开头的函数都返回`type`类型的值，例如这里的`@This()`。

这里的成员被命名为`This`，但这不是强制的，用你喜欢的就行。
:::

### 初始化和反初始化

让我们找一个地方来初始化数据结构。

按照约定俗成，一般声明一个名为`init`的函数作为初始化函数，一个名为`deinit`的函数作为反初始化函数。

函数应该放在哪里呢？在C中，我们把成员定义在结构体内，然后在结构体外用一个很长的前缀来区分，比如：

```c
typedef struct {
    int *items;
    int len;
} SimpleArrayListInt;

void simple_array_list_int_init(SimpleArrayListInt*);
```

在Python中，我们会直接在类的定义内定义一个特殊的函数，比如：

```python
class SimpleArrayInit():
    def __init__(self):
        pass
```

在Zig中，我们结合这两种形式：在结构体内声明函数，比如：

```zig {9}
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
    };
}
```

除了`init`，我们还需要一个对应的`deinit`，以便在需要的时候释放申请的内存。在这里，我们需要释放`items`这个成员。

```zig
        pub fn deinit(self: This) void {
            self.allocator.free(self.items);
        }
```

组装起来，我们就有了一个SimpleArrayList的基本框架：

```zig
const std = @import("std");

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
    const a = try SimpleArrayList(i8).init(std.heap.page_allocator);
    defer a.deinit();
    std.debug.print("{} of {}\n", .{ a.len, a.items.len });
}
```

```ansi
$stdout returns nothing.
$stderr:
0 of 10
```

从运行结果我们可以看出，我们成功地分配了10个元素的空间，不过暂时还没有存储任何元素进去。

::: tip
另外，这里我们又遇见了一个不认识的关键词——`defer`。如果你有Go语言的使用经验，这可能会很眼熟。在defer关键词后的语句会在当前作用域结束时被执行。不严谨地说，会在下一个花括号后执行。下面的例子可以说明不同的执行顺序。
```zig
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    print("1\n", .{});  // 打印1
    defer print("2\n", .{});

    {
        defer print("3\n", .{});
        print("4\n", .{});  // 打印4
        {
            defer print("5\n", .{});
            print("6\n", .{});  // 打印6
        }   // 打印5
    }   // 打印3

}   // 打印2
```

```ansi
$stdout returns nothing.
$stderr:
1
4
6
5
3
2
```

:::

::: warning
我们应该在不需要一块内存后尽可能地释放掉它，以便减轻管理内存的复杂度。

大量分配内存而不释放会导致**内存泄漏**，造成资源浪费。
:::

我们还需要什么函数呢？我们想要获取某个下标处的元素，想要修改某个下标处的元素，想要插入新的元素，想要在列表末尾添加新的元素。总结一下，我们至少需要下面的四个函数：

1. nth(n)：访问下标为n的元素；
2. setNth(n, v)：将下标为n的元素设置为v；
3. insertNth(n, v)：在下标n处插入元素v；
4. append(v)：在列表末尾追加元素v；
5. removeNth(n)：删除下标为n的元素；

我们从`nth`开始吧。

### nth

最符合直觉的，我们从`items`成员中取出一个元素：

```zig
pub fn nth(self: This, n: usize) T {
    return self.items[n];
}
```

在这里，我们注意到一个新的概念——self。如果你有使用Python的经验，你应该会觉得眼熟。这里的self指的是被成员访问运算符`.`访问的对象，比如说如果我们调用`list.nth(1)`，那么这里的self就是list。

self也可以叫其他名字，只要他是第一个参数就行。当结构体内的某个函数的第一个参数为self（也可以叫其他名字）时，我们称它为一个**方法**。

如果我们需要修改self的内容的话，也可以传入指针作为第一个参数。

上面的实现有一个很大的问题：`n`这个位置上不一定有元素，`items`也不一定有这么大，这会造成被称为**下标越界**的问题。在这里，我们对下标n进行检查，如果超出边界就返回错误，如果正常访问则返回元素。没错，我们将会用到错误联合类型。

```zig
pub fn nth(self: This, n: usize) !T {
    if (n >= self.len) {
        return error.IndexOutOfBound;
    }
    return self.items[n];
}
```

因为n是usize类型，所以它不会小于0；`self.len`一定小于等于`self.items.len`，所以只要n大于self.len，就没有必要判断是否大于self.items.len，一定是下标越界。

### setNth

类似于`nth`，`setNth`也要检查边界。当发生下标越界时，我们返回一样的错误；当没有发生错误时，我们返回void。

```zig
pub fn setNth(self: *This, n: usize, v: T) !void {
    if (n >= self.len) {
        return error.IndexOutOfBound;
    }
    self.items[n] = v;
}
```

正如前文所言，此处我们需要修改列表，因此我们传入的参数类型为指针。

::: warning
假设你有一个列表的实例`a`，你希望通过`setNth`来设置元素，那么你必须声明a为一个可变量，也就是必须通过`var`关键词声明这个变量：

```zig
var a = try SimpleArrayList(i8).init(std.heap.page_allocator);
defer a.deinit();
std.debug.print("{!}\n", .{a.setNth(10, 8)});
```

如果你使用`const`声明了一个不可变量，编译器将会报错。

```zig
// error: expected type '*02_array.SimpleArrayList(i8)', found '*const 02_array.SimpleArrayList(i8)'
const a = try SimpleArrayList(i8).init(std.heap.page_allocator);
defer a.deinit();
std.debug.print("{!}\n", .{a.setNth(10, 8)});
```
:::

### append

在实现`insertNth`之前，我们先实现相对简单的`append`。

我们的基本诉求是在列表的末尾添加一个元素，最简化的实现如下：

```zig
pub fn append(self: *This, v: T) void {
    self.items[self.len] = v;
    self.len += 1;
}
```

我们会遇到一个问题：在`init`函数里，我们只给`items`分配了10个元素的空间，如果我们通过上面的这个`append`添加了11个元素，就会超出items的范围，遇到下标越界。这该怎么办？我们只需要在添加元素前，判断空间是否足够，如果不够就扩容。这样，就不会出现空间不足的问题。我们增加一个新的方法`enlarge`来增大空间。

#### enlarge

这个方法的基本流程为：

1. 分配更大的空间；
2. 复制元素到新的空间中；
3. 释放原来的空间；

一个简单的实现如下：

```zig
pub fn enlarge(self: *This) !void {
    // 计算“更大的空间”有多大
    // 因为Zig不会进行不安全的隐式类型转换，为了让usize类型的self.items.len和1.5相乘，我们必须手动进行转换
    const new_capacity: usize = @intFromFloat(@as(f32, @floatFromInt(self.items.len)) * @as(f32, 1.5));
    // 1. 分配更大的空间
    const new_items = try self.allocator.alloc(T, new_capacity);
    // 2. 复制元素到新空间中
    std.mem.copyForwards(T, new_items, self.items);
    // 3. 释放原来的空间
    self.allocator.free(self.items);
    self.items = new_items;
}
```

我们将代码段对应的步骤写在了注释中。

有了enlarge，我们终于可以实现append了。

#### append

append的基本步骤为：

1. 判断空间是否充足，是则到步骤3，否则到步骤2；
2. 使用enlarge方法扩大空间；
3. 在末尾增加元素；

```zig
pub fn append(self: *This, v: T) !void {
    // 1. 判断大小
    if (self.len >= self.items.len) {
        // 2. 扩大空间
        try self.enlarge();
    }
    // 增加元素
    self.items[self.len] = v;
    self.len += 1;
}
```
### insertNth

`insertNth`的操作和`append`有很多相似之处，并且需要进行下标检查，基本步骤包括：

1. 判断下标是否越界，是则返回下标越界错误，否则继续；
2. 判断空间是否充足，是则到步骤4，否则到步骤3；
3. 使用enlarge方法扩大空间；
4. 判断n位置是否有元素，有则到步骤5，否则到步骤6；
5. 将n位置的元素及其后面的元素全部后移一位；
6. 在n位置插入元素；

```zig
pub fn insertNth(self: *This, n: usize, v: T) !void {
    // 1. 判断下标是否越界
    // 与nth和setNth不同，我们允许n等于self.len，此时insertNth相当于append
    if (n > self.len) {
        return error.IndexOutOfBound;
    }
    // 2. 判断空间是否充足
    if (self.len >= self.items.len) {
        // 3. 使用enlarge方法扩大空间
        try self.enlarge();
    }
    // 4,5. 将n位置后面的元素往后移一位
    // 在实际实践中，只有在n等于self.len时，n位置上才没有元素，所以可以跳过判断这一步
    var i = self.len;
    while (i >= n + 1) : (i -= 1) {
        self.items[i] = self.items[i - 1];
    }
    // 6. 在n位置插入元素
    self.items[n] = v;
    self.len += 1;
}
```

### removeNth

`removeNth`删除下标n处的元素，因此我们需要进行下标检查。因为列表中存储的元素可能需要进行反初始化等操作，所以我们不应该直接覆盖这个元素，而应该返回这个元素。综上，基本步骤为：

1. 判断下标是否越界，是则返回下标越界错误，否则继续；
2. 将n位置处元素保存为temp；
3. 将n位置之后的元素全部前移一位；
4. 返回temp；

```zig
pub fn removeNth(self: *This, n: usize) !T {
    // 1. 判断下标是否越界
    if (n >= self.len) {
        return error.IndexOutOfBound;
    }
    // 2. 将n位置处元素保存为temp
    const temp = self.items[n];
    // 3. 将n位置之后的元素全部前移一位
    for (n..self.len - 1) |i| {
        self.items[i] = self.items[i + 1];
    }
    self.len -= 1;
    // 4. 返回temp
    return temp;
}
```

::: tip
所有涉及到`nth`，也就是通过下标访问的方法，都应该进行下标检查。
:::

## 测试

## 挑战

在实际使用中，还有很多我们没有实现的常用方法。在这里，我们给出其中的一部分，给你作为挑战。

1. reverse：翻转列表，例如列表`1, 2, 3`在翻转后变为`3, 2, 1`；
2. pop：删除最后一个元素，然后返回这个元素；
3. clear：删除所有元素；

🚧施工中🚧

