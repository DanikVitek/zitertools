const it = @import("root.zig");
const Item = it.Item;
const IterError = it.IterError;

/// Returns the return type of the `find`/`findContext` function.
pub fn Find(comptime Iter: type, comptime PredicateES: ?type) type {
    return if (IterError(Iter)) |ES|
        (if (PredicateES) |PES| (ES || PES)!?Item(Iter) else ES!?Item(Iter))
    else
        (if (PredicateES) |PES| PES!?Item(Iter) else ?Item(Iter));
}

/// Searches for an element in an iterator that satisfies the given predicate.
///
/// Find is short-circuiting, i.e. it will stop processing as soon as the predicate returns true.
///
/// Note that `find(iter, f)` is equivalent to `filter(iter, f).next()`.
///
/// You can still use the iterator after calling this function.
pub fn find(
    iter: anytype,
    comptime predicate: anytype,
) Find(
    @typeInfo(@TypeOf(iter)).Pointer.child,
    switch (@typeInfo(@TypeOf(predicate))) {
        .Fn => |Fn| switch (@typeInfo(Fn.return_type orelse @compileError("predicate must be a function that returns a `bool` or `!bool`"))) {
            .Bool => null,
            .ErrorUnion => |EU| EU.error_set,
            else => @compileError("predicate must be a function that returns a `bool` or `!bool`"),
        },
        else => @compileError("predicate must be a function that returns a `bool` or `!bool`"),
    },
) {
    const validatedPredicate = it.validatePredicateFn(@typeInfo(@TypeOf(iter)).Pointer.child, predicate);
    const iter_has_error = comptime IterError(@typeInfo(@TypeOf(iter)).Pointer.child) != null;
    const predicate_has_error = comptime @typeInfo(@TypeOf(validatedPredicate)) == .ErrorUnion;
    while (if (iter_has_error) try iter.next() else iter.next()) |item| {
        const predicate_result: bool = if (predicate_has_error)
            try validatedPredicate(&item)
        else
            validatedPredicate(&item);
        if (predicate_result) return item;
    }
    return null;
}

/// Searches for an element in an iterator that satisfies the given predicate with context.
///
/// Find is short-circuiting, i.e. it will stop processing as soon as the predicate returns true.
///
/// Note that `findContext(iter, c, f)` is equivalent to `filterContext(iter, c, f).next()`.
///
/// You can still use the iterator after calling this function.
pub fn findContext(
    iter: anytype,
    context: anytype,
    comptime predicate: anytype,
) Find(
    @typeInfo(@TypeOf(iter)).Pointer.child,
    switch (@typeInfo(@TypeOf(predicate))) {
        .Fn => |Fn| switch (@typeInfo(Fn.return_type orelse @compileError("predicate must be a function that returns a `bool` or `!bool`"))) {
            .Bool => null,
            .ErrorUnion => |EU| EU.error_set,
            else => @compileError("predicate must be a function that returns a `bool` or `!bool`"),
        },
        else => @compileError("predicate must be a function that returns a `bool` or `!bool`"),
    },
) {
    const validatedPredicate = it.validatePredicateContextFn(
        @typeInfo(@TypeOf(iter)).Pointer.child,
        @TypeOf(context),
        predicate,
    );
    const iter_has_error = comptime IterError(@typeInfo(@TypeOf(iter)).Pointer.child) != null;
    const predicate_has_error = comptime @typeInfo(@TypeOf(validatedPredicate)) == .ErrorUnion;
    while (if (iter_has_error) try iter.next() else iter.next()) |item| {
        const predicate_result: bool = if (predicate_has_error)
            try validatedPredicate(context, &item)
        else
            validatedPredicate(context, &item);
        if (predicate_result) return item;
    }
    return null;
}

const testing = @import("std").testing;

test "find 'o'" {
    const slice: []const u8 = "Hello, world!";
    var iter = it.sliceIter(u8, slice);

    const predicate = struct {
        fn predicate(item: *const u8) bool {
            return item.* == 'o';
        }
    }.predicate;
    try testing.expectEqual(@as(?u8, 'o'), find(&iter, predicate));
    try testing.expectEqual(@as(usize, 5), iter.index);
    try testing.expectEqual(@as(?u8, ','), iter.next());
    try testing.expectEqual(@as(?u8, 'o'), find(&iter, predicate));
    try testing.expectEqual(@as(usize, 9), iter.index);
    try testing.expectEqual(@as(?u8, null), find(&iter, predicate));
}
