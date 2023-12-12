const std = @import("std");
const testing = std.testing;

const itertools = @import("main.zig");
const Item = itertools.Item;

/// Iter type for iterating over slice values
pub fn SliceIter(comptime T: type) type {
    return struct {
        const Self = @This();

        slice: []const T,
        index: usize,

        pub fn next(self: *Self) ?T {
            if (self.index >= self.slice.len)
                return null;
            self.index += 1;
            return self.slice[self.index - 1];
        }

        pub fn nth(self: *Self, n: usize) ?T {
            if (self.index + n >= self.slice.len)
                return null;
            self.index += n;
            return self.slice[self.index + 1 - n];
        }

        pub fn len(self: *const Self) usize {
            return if (self.index <= self.slice.len) self.slice.len - self.index else 0;
        }
    };
}

/// Returns an iterator iterating over the values in the slice.
pub fn sliceIter(comptime T: anytype, slice: anytype) SliceIter(T) {
    return .{ .slice = slice, .index = 0 };
}

test "sliceIter" {
    const slice: []const u32 = &.{ 1, 2, 3, 4 };
    var iter = sliceIter(u32, slice);

    try testing.expectEqual(u32, Item(@TypeOf(iter)));
    try testing.expectEqual(@as(?u32, 1), iter.next());
    try testing.expectEqual(@as(?u32, 2), iter.next());
    try testing.expectEqual(@as(?u32, 3), iter.next());
    try testing.expectEqual(@as(?u32, 4), iter.next());
    try testing.expectEqual(@as(?u32, null), iter.next());
    try testing.expectEqual(@as(?u32, null), iter.next());
}
