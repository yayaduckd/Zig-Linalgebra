const std = @import("std");
const la = @import("main.zig");

var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpallocator.allocator();
const stdout = std.io.getStdOut().writer();


pub fn main() anyerror!void {

    var testMatrixA = la.Matrix.zeroes(allocator, 4, 2) catch unreachable;
    try testMatrixA.set(1, 1, 1.0);
    try testMatrixA.set(1, 2, 2.0);
    try testMatrixA.set(2, 1, 3.0);
    try testMatrixA.set(2, 2, 4.0);
    try testMatrixA.set(3, 1, 5.0);
    try testMatrixA.set(3, 2, 6.0);
    try testMatrixA.set(4, 1, 7.0);
    try testMatrixA.set(4, 2, 8.0);

    var testMatrixB = la.Matrix.zeroes(allocator, 2, 4) catch unreachable;
    try testMatrixB.set(1, 1, 1.0);
    try testMatrixB.set(1, 2, 2.0);
    try testMatrixB.set(1, 3, 3.0);
    try testMatrixB.set(1, 4, 4.0);
    try testMatrixB.set(2, 1, 5.0);
    try testMatrixB.set(2, 2, 6.0);
    try testMatrixB.set(2, 3, 7.0);
    try testMatrixB.set(2, 4, 8.0);

    var resultMatrix = la.multiply(&testMatrixA, &testMatrixB, allocator) catch unreachable;
    try testMatrixA.print(stdout);
    try stdout.print("-------------------------------\n", .{});
    try testMatrixB.print(stdout);
    try stdout.print("-------------------------------\n", .{});
    try resultMatrix.print(stdout);

    // var expectedRowVector = la.Vector.zeroes(allocator, 2) catch unreachable;
    // try expectedRowVector.set(1, 5.0);
    // try expectedRowVector.set(2, 6.0);

    // var gottenRow = la.getRow(&testMatrixA, 3, allocator) catch unreachable;
    // try testMatrixA.print(stdout);
    // try stdout.print("-------------------------------\n", .{});
    // try gottenRow.print(stdout);

}
