# run_z_md.ts Examples

- 使用`bun run_z_md.ts run <文件名>`来运行脚本

- 其他语言的代码段不会被执行：

```python
print('我不会被执行！')
```

- 带有`-skip`标记的代码段不会被执行:

```zig -skip
// 我不会被执行！
```

- 普通的zig代码段将会被嵌入到基本的模板中执行：

```zig
std.debug.print("Hello {s}!\n", .{"World"});
```

模板为：
```zig -skip
const std = @import("std");

pub fn main() !void {
    // 代码被插入到这里
}
```

- 带有`-singleFile`的代码段将被作为一个单独的文件执行：

```zig -singleFile
const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello {s}!\n", .{"World"});
}
```

- 带有`-collect_数字`的代码段将被收集起来，相同的数字的代码块会被放到一起，如果用星号*代替数字，代码块里的内容将被放在所有代码块前面：

```zig -collect_*
const std = @import("std");
```

```zig -collect_1
const code_snippet: u32 = 1;
```

```zig -collect_2
const code_snippet: u32 = 2;
```

- 带有`-execute_数字`的代码段类似于上一个，代码段将被收集起来，相同的数字的代码块会被放到一起，然后被立即执行：

```zig -execute_1
pub fn main() void {
    std.debug.print("Hello Collect! {}\n", .{code_snippet});
}
```

上面的代码段被拼接为：
```zig -skip
const std = @import("std");
const code_snippet: u32 = 1;
pub fn main() void {
    std.debug.print("Hello Collect! {}\n", .{code_snippet});
}
```

```zig -execute_2
pub fn main() void {
    std.debug.print("Hello Collect {}!\n", .{code_snippet});
}
```

上面的代码段被拼接为：
```zig -skip
const std = @import("std");
const code_snippet: u32 = 2;
pub fn main() void {
    std.debug.print("Hello Collect! {}\n", .{code_snippet});
}
```

- `-execute_*`是不合法的，会导致脚本报错退出