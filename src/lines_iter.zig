const std = @import("std");
const SplitIterator = std.mem.SplitIterator;

pub const LinesIter = struct {
    split_iter: SplitIterator(u8, .scalar),

    pub fn next(self: *LinesIter) ?[]const u8 {
        const start = self.split_iter.index orelse return null;
        const line_non_inclusive = self.split_iter.next().?;
        const end = self.split_iter.index orelse start + line_non_inclusive.len;
        const line = self.split_iter.buffer[start..end];
        const line_stripped = blk: {
            const line_without_lf = strip_suffix(line, "\n") orelse break :blk line;
            const line_without_crlf = strip_suffix(line_without_lf, "\r") orelse break :blk line_without_lf;
            break :blk line_without_crlf;
        };

        return line_stripped;
    }

    fn strip_suffix(line: []const u8, suffix: []const u8) ?[]const u8 {
        if (line.len < suffix.len) return null;
        if (!std.mem.eql(u8, line[line.len - suffix.len ..], suffix)) return null;
        return line[0 .. line.len - suffix.len];
    }
};

pub fn lines(input: []const u8) LinesIter {
    return .{ .split_iter = std.mem.splitScalar(u8, input, '\n') };
}

const testing = std.testing;

test "basic usage" {
    const text = "foo\r\nbar\n\nbaz\r";
    var text_lines = lines(text);

    try testing.expectEqualStrings("foo", text_lines.next().?);
    try testing.expectEqualStrings("bar", text_lines.next().?);
    try testing.expectEqualStrings("", text_lines.next().?);
    try testing.expectEqualStrings("baz\r", text_lines.next().?);
    try testing.expect(text_lines.next() == null);
}

test "the final line doesn't require any ending" {
    const text = "foo\r\nbar\n\nbaz";
    var text_lines = lines(text);

    try testing.expectEqualStrings("foo", text_lines.next().?);
    try testing.expectEqualStrings("bar", text_lines.next().?);
    try testing.expectEqualStrings("", text_lines.next().?);
    try testing.expectEqualStrings("baz", text_lines.next().?);
    try testing.expect(text_lines.next() == null);
}
