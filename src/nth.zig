const std = @import("std");

const itertools = @import("main.zig");
const Item = itertools.Item;
const IterError = itertools.IterError;

pub fn Nth(comptime IterPtr: type) type {
    const Iter = switch (@typeInfo(IterPtr)) {
        .Pointer => |Pointer| if (Pointer.size == .One)
            Pointer.child
        else
            @compileError("Expected mutable single-item pointer to iterator"),
        else => @compileError("Expected mutable single-item pointer to iterator"),
    };
    return if (IterError(Iter)) |ES| ES!?Item(Iter) else ?Item(Iter);
}

pub fn nth(iter: anytype, n: usize) callconv(if (iterHasNth(@TypeOf(iter))) .Inline else .Unspecified) Nth(@TypeOf(iter)) {
    if (comptime iterHasNth(@TypeOf(iter))) {
        return iter.nth(n);
    }
    const has_error = comptime IterError(@typeInfo(@TypeOf(iter)).Pointer.child) != null;
    const item = (if (has_error) try iter.next() else iter.next()) orelse return null;
    return if (n == 0) item else @call(.always_tail, nth, .{ iter, n - 1 });
}

fn iterHasNth(comptime IterPtr: type) bool {
    const Iter = switch (@typeInfo(IterPtr)) {
        .Pointer => |Pointer| if (Pointer.size == .One)
            Pointer.child
        else
            @compileError("Expected mutable single-item pointer to iterator"),
        else => @compileError("Expected mutable single-item pointer to iterator"),
    };
    if (@hasDecl(Iter, "nth")) {
        switch (@typeInfo(@TypeOf(Iter.nth))) {
            .Fn => |Fn| if (Fn.params.len == 2 and Fn.params[0].type == *Iter and Fn.params[1].type == usize and Fn.return_type == Nth(*Iter)) {
                return true;
            },
            else => {},
        }
    }
    return false;
}

const testing = @import("std").testing;

test "nth" {
    var iter = itertools.range(@as(u8, 0), 10);
    try testing.expectEqual(@as(?u8, 5), nth(&iter, 5));
    try testing.expectEqual(@as(?u8, 6), nth(&iter, 0));
    try testing.expectEqual(@as(?u8, null), nth(&iter, 3));
}

test "nth far" {
    var iter = itertools.range(@as(u8, 0), 10);
    try testing.expectEqual(@as(?u8, null), nth(&iter, 15));
}

test "nth error" {
    var iter = TestErrorIter.init(5);
    try testing.expectError(error.TestErrorIterError, nth(&iter, 5));
}

test "nth optimal" {
    var iter = itertools.sliceIter(u8, &.{ 1, 2, 3, 4 });
    try testing.expectEqual(@as(?u8, 2), nth(&iter, 1));
    try testing.expectEqual(@as(?u8, 3), nth(&iter, 0));
    try testing.expectEqual(@as(?u8, null), nth(&iter, 1));
}

const TestErrorIter = struct {
    const Self = @This();

    counter: usize = 0,
    until_err: usize,

    pub fn init(until_err: usize) Self {
        return .{ .until_err = until_err };
    }

    pub fn next(self: *Self) !?usize {
        if (self.counter >= self.until_err) return error.TestErrorIterError;
        self.counter += 1;
        return self.counter - 1;
    }
};
