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

        pub fn isEmpty(self: This) usize {
            return self.top() == 0;
        }

        pub fn deinit(self: *This) void {
            self.data.deinit();
        }
    };
}
```

首先，我们保存了This和List两个类型，来方便我们的后续使用。通过保存List，在有需要的时候，我们可以方便地把List的值修改为其他值，而不用修改代码中其他出现List的地方。

随后，我们保存了一个allocator，并用这个allocator初始化了一个列表的示例用来保存数据。

然后，我们创建了初始化函数init和反初始化方法deinit，这个和前面的没有差别。

最后，我们创建了`top`方法和`isEmpty`方法。`top`方法返回下一个进入到栈中（入栈）的元素应该被保存到哪，而`isEmpty`方法判断栈是不是为空。我们将会进场用到这两个方法，把它们作为单独的方法可以让我们的程序更加清晰，也更加便于修改。

## 基本操作

栈并不复杂，它有下面的主要方法：

1. pop：返回最后一个元素，并从栈中移除这个元素；
2. push：入栈一个元素；
3. peek：返回最后一个元素，但不移除；

借助于先前实现的SimpleArrayList，我们可以不用手动管理内存了！

我们一个一个来。

### pop

### push

### peek

## 测试

### pop

### push

### peek

## 应用示例 - 括号匹配

## 挑战

## 完整代码

🚧施工中🚧

