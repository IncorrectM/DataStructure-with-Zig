# Linked List 链表

链表是一种线性数据结构，它通过指针链接一系列节点来存储数据。

你可以想象为站在不同地方的人手里拿着绳子连在一起，虽然不知道彼此具体在哪，但总是可以通过绳子进行沟通。

![链表示意](./imgs/03/0301_linked_list.png)

在开始前，我还要再重复一遍我的意见：不要将我们实现的代码投入到生产中。Zig标准库提供了[std.SinglyLinkedList](https://ziglang.org/documentation/master/std/#std.SinglyLinkedList)这一实现。

## 节点

在链表中，所有的数据都被保存在**节点**中，每个节点保存着指向下一个节点的指针。

让我们从定义节点开始。

```zig -skip
pub fn LinkedListNode(comptime T: type) type {
    return struct {
        const This = @This();
        data: T,
        next: ?*This,

        pub fn init(data: T) This {
            return .{
                .data = data,
                .next = null,
            };
        }
    };
}
```

显而易见的，我们需要一个init函数来初始化节点。不过我们不需要deinit函数，我们会将所有节点的deinit放置在链表中。

## 链表的初始化和反初始化

接下来，我们实现链表最基本的两个函数——初始化和反初始化。

```zig -skip
const std = @import("std");
pub fn LinkedList(comptime T: type) type {
    return struct {
        const Node = LinkedListNode(T);
        const This = @This();
        allocator: std.mem.Allocator,
        head: ?*Node,
        length: usize,

        pub fn init(allocator: std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .head = null,
                .length = 0,
            };
        }

        pub fn deinit(self: *This) void {
            var next = self.head;
            while (next != null) {
                const cur = next.?;
                next = cur.next;
                if (@hasDecl(T, "deinit")) {
                    // 反初始化节点里的数据
                    cur.data.deinit();
                }
                // 释放节点
                self.allocator.free(cur);
            }
        }
    };
}
```

我们从成员开始看起。

首先，我们要保存节点的类型为Node，保存本身的类型This。我们需要保存第一个节点的指针。另外，为了方便判断长度，我们保存长度为length。

::: details 为什么保存length?
和列表一样，链表的长度应该等于链表中元素的数量。

因为链表中的元素是分散在各处的，必须要通过指针一个一个数。沿用前面的比喻，就像让人通过绳子一个一个报数。显然，伴随着人越来越多，这个过程将会越来越慢。

为了加速这个过程，我们直接保存长度，在增加节点和删除节点时修改这个值。
:::

然后，让我们看初始化函数。初始化函数非常的普通，只是保存一些必要的信息。

最后是反初始化方法。

第一眼望去，我们看到了一个先前没有见过的函数`@hasDecl()`。这同样是一个内建函数，它可以判断传入的类型（第一个参数）是否声明了给定的成员（第二个参数）。这有一点像一些语言中的反射。在这里，我们通过这个函数来判断节点里的数据需不需要反初始化，需要则执行反初始化。

Ok，到这里我们可以想想需要什么方法了。

## 链表的常用方法

类似于列表，我们第一个想到的就是最基本的增删查改：

1. nth(n)：获取第n个节点；
2. append(v)：在链表末尾追加元素v；
3. remove(node)：从链表中移除节点node；

和列表不同，在链表中我们一般不通过下标访问。我们主要访问第一个元素和最后一个元素，所以我们还有下面的方法：

1. prepend(v)：在链表头插入元素v；
2. popFirst()：移除链表头上的节点；
3. popLast()：移除链表末尾的节点；

::: tip
在这里，我们使用元素作为插入的单位，这样子我们可以让链表自己来负责节点的初始化和反初始化。但在一些实现中，插入的单位是节点，例如Zig的标准库[std.SinglyLinkedList](https://ziglang.org/documentation/master/std/#std.SinglyLinkedList)。
:::

### nth

我们要一个一个数过来，直到数到第n个未知。

因为我们在结构体中保存了链表的长度，所以我们可以在一个一个找之前先判断有没有。不过，在链表中，我们一般不会返回下标越界错误，而是返回一个空值，表示我们没找到。

于是，我们有这样的实现：

```zig -skip
pub fn nth(self: This, n: usize) ?T {
    if (n >= self.length) {
        return null;
    }
    var next = self.head;
    var i: usize = 0;
    while (next != null and i != n) : (i += 1) {
        next = next.?.next;
    }
    return next;
}
```

### append
### remove
### prepend
### popFirst

## 挑战 - 双链表

🚧施工中🚧