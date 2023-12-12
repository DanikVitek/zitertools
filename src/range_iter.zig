const std = @import("std");
const testing = std.testing;

const itertools = @import("main.zig");
const Item = itertools.Item;

/// A (half-open) range iterator bounded inclusively below and exclusively above [start, end).
pub fn RangeIter(comptime T: type) type {
    if (!std.meta.trait.isNumber(T))
        @compileError("RangeIter Item type must be a number");

    return struct {
        const Self = @This();

        current: T,
        end: T,
        step: T,

        pub fn stepBy(self: Self, step: T) Self {
            return .{
                .current = self.current,
                .end = self.end,
                .step = step,
            };
        }

        pub fn next(self: *Self) ?T {
            const is_vector = comptime @typeInfo(T) == .Vector;
            const zero = comptime @as(T, if (is_vector) @splat(0) else 0);
            if (self.step > zero and self.current >= self.end or
                self.step < zero and self.current <= self.end)
                return null;
            const result = self.current;
            self.current += self.step;
            return result;
        }
    };
}

/// Creates a `RangeIter`. See its documentation for more info.
pub fn range(start: anytype, end: @TypeOf(start)) RangeIter(@TypeOf(start)) {
    const T = @TypeOf(start);
    return .{
        .current = start,
        .end = end,
        .step = switch (@typeInfo(T)) {
            .Int, .Float => @as(T, 1),
            .Vector => |Vector| switch (@typeInfo(Vector.child)) {
                .Int, .Float => @as(T, @splat(1)),
                else => @compileError("RangeIter Item type must be a number or vector of numbers"),
            },
            else => @compileError("RangeIter Item type must be a number or vector of numbers"),
        },
    };
}

test "RangeIter" {
    var iter = range(@as(u32, 0), 5);
    try testing.expectEqual(u32, Item(@TypeOf(iter)));
    try testing.expectEqual(@as(?u32, 0), iter.next());
    try testing.expectEqual(@as(?u32, 1), iter.next());
    try testing.expectEqual(@as(?u32, 2), iter.next());
    try testing.expectEqual(@as(?u32, 3), iter.next());
    try testing.expectEqual(@as(?u32, 4), iter.next());
    try testing.expectEqual(@as(?u32, null), iter.next());
    try testing.expectEqual(@as(?u32, null), iter.next());
}

test "RangeIter reverse" {
    var iter = range(@as(i32, 5), 0).stepBy(-1);
    try testing.expectEqual(i32, Item(@TypeOf(iter)));
    try testing.expectEqual(@as(?i32, 5), iter.next());
    try testing.expectEqual(@as(?i32, 4), iter.next());
    try testing.expectEqual(@as(?i32, 3), iter.next());
    try testing.expectEqual(@as(?i32, 2), iter.next());
    try testing.expectEqual(@as(?i32, 1), iter.next());
    try testing.expectEqual(@as(?i32, null), iter.next());
    try testing.expectEqual(@as(?i32, null), iter.next());
}
