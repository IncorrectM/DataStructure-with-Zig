const std = @import("std");
const hash_table_lib = @import("06_hash_table.zig");
const HashTable = hash_table_lib.HashTable;

const WordFreq = struct {
    word: []const u8, // 单词
    freq: u32, // 词频
};

pub fn getWord(word_freq: WordFreq) []const u8 {
    return word_freq.word;
}

pub fn stringEql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) {
        return false;
    }
    for (a, b) |c1, c2| {
        if (std.ascii.toLower(c1) != std.ascii.toLower(c2)) {
            return false;
        }
    }
    return true;
}

pub fn special_djb2(str: []const u8) usize {
    var hash: usize = 5381;

    for (str) |c| {
        // 直接对C进行左移5位的操作可能会超出u8的表示范围，
        //    因此需要显式地转换为更大的数据类型
        const larger_c: usize = @intCast(std.ascii.toLower(c));
        hash += (larger_c << 5) + larger_c;
    }

    return hash;
}

pub fn countWordFreq(sentence: []const u8, hash_table: *HashTable([]const u8, WordFreq)) !void {
    var word_itr = std.mem.splitAny(u8, sentence, " ,./;'[]\\—-=<>?:\"{}|_+`~!@#$%^&*()");
    // 遍历单词
    while (word_itr.next()) |word| {
        if (std.mem.eql(u8, word, "")) {
            // 忽略空字符串
            continue;
        }
        const record = hash_table.get(word);
        if (record) |r| {
            // 已有的词频加1
            hash_table.remove(word);
            try hash_table.put(.{
                .word = word,
                .freq = r.freq + 1,
            });
        } else {
            // 没有的词频设置为1
            try hash_table.put(.{
                .word = word,
                .freq = 1,
            });
        }
    }
}

test "count word freqs" {
    const allocator = std.testing.allocator;

    const sentence: []const u8 = "The Time Traveller (for so it will be convenient to speak of him) was expounding a recondite matter to us. His pale grey eyes shone and twinkled, and his usually pale face was flushed and animated. The fire burnt brightly, and the soft radiance of the incandescent lights in the lilies of silver caught the bubbles that flashed and passed in our glasses. Our chairs, being his patents, embraced and caressed us rather than submitted to be sat upon, and there was that luxurious after-dinner atmosphere, when thought runs gracefully free of the trammels of precision. And he put it to us in this way—marking the points with a lean forefinger—as we sat and lazily admired his earnestness over this new paradox (as we thought it) and his fecundity.";
    const expected = [_]WordFreq{
        .{ .word = "and", .freq = 10 },
        .{ .word = "the", .freq = 8 },
        .{ .word = "of", .freq = 5 },
        .{ .word = "his", .freq = 5 },
        .{ .word = "to", .freq = 4 },
        .{ .word = "it", .freq = 3 },
        .{ .word = "was", .freq = 3 },
        .{ .word = "us", .freq = 3 },
        .{ .word = "in", .freq = 3 },
        .{ .word = "be", .freq = 2 },
        .{ .word = "a", .freq = 2 },
        .{ .word = "pale", .freq = 2 },
        .{ .word = "that", .freq = 2 },
        .{ .word = "our", .freq = 2 },
        .{ .word = "sat", .freq = 2 },
        .{ .word = "thought", .freq = 2 },
        .{ .word = "this", .freq = 2 },
        .{ .word = "as", .freq = 2 },
        .{ .word = "we", .freq = 2 },
        .{ .word = "time", .freq = 1 },
        .{ .word = "traveller", .freq = 1 },
        .{ .word = "for", .freq = 1 },
        .{ .word = "so", .freq = 1 },
        .{ .word = "will", .freq = 1 },
        .{ .word = "convenient", .freq = 1 },
        .{ .word = "speak", .freq = 1 },
        .{ .word = "him", .freq = 1 },
        .{ .word = "expounding", .freq = 1 },
    };
    var hash_table = try HashTable([]const u8, WordFreq).init(
        allocator,
        &special_djb2,
        &getWord,
        &stringEql,
        10,
    );
    defer hash_table.deinit();

    try countWordFreq(sentence, &hash_table);

    for (expected) |exp| {
        const actual = hash_table.get(exp.word);
        try std.testing.expect(actual != null);
        std.debug.print("{s}: actual freq: {}, exp freq: {}\n", .{ exp.word, actual.?.freq, exp.freq });
        try std.testing.expect(actual.?.freq == exp.freq);
    }
}
