# Array 数组

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

- 静态数组的定义与基本操作（添加、获取、修改）
- 动态数组的简单实现（扩容策略）
- 基础内存管理示例

🚧施工中🚧

