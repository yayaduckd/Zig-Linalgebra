const std = @import("std");
const la = @import("main.zig");

var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
// var testingallocator = std.testing.allocator()
var allocator = gpallocator.allocator();
const stdout = std.io.getStdOut().writer();

pub fn printSeparatorLine(writer: anytype) !void {
    try writer.print("-------------------------------\n", .{});
}

pub fn run() anyerror!void {

    // var identityMatrix5 = la.Matrix.identity(allocator, 5);
    // try identityMatrix5.print(stdout);

    // var array = [_]la.LAType{ 1,  2,  3,  4,  5,  6,
    //                           7,  8,  9, 10, 11, 12,
    //                          13, 14, 15, 16, 17, 18,
    //                          19, 20, 21, 22, 23, 24,
    //                          25, 26, 27, 28, 29, 30,
    //                          31, 32, 33, 34, 35, 36 };
    // var matBase = array[0..];


    // var A = la.Matrix.fromSlice(allocator, 6, 6, matBase);

    // nonsingular example
    // var array = [_]la.LAType{2, 5, 0, 8,
    //                          1, 4, 2, 6,
    //                          7, 8, 9, 3,
    //                          1, 5, 7, 8};
    // var matBase = array[0..];


    // var A = la.Matrix.fromSlice(allocator, 4, 4, matBase);
    var array = [_]la.LAType{1, 2, -1,
                             2, -1, 3,
                             3,  1, 2};
    var matBase = array[0..];


    var A = la.Matrix.fromSlice(allocator, 3, 3, matBase);
    defer A.deinit(allocator);
    
    try A.print(stdout);

    try printSeparatorLine(stdout);
    
    la.rowReduce(&A, allocator);
    try A.print(stdout);

    // var testMatrixB = la.Matrix.zeroes(allocator, 2, 4) catch unreachable;
    // try testMatrixB.set(1, 1, 1.0);
    // try testMatrixB.set(1, 2, 2.0);
    // try testMatrixB.set(1, 3, 3.0);
    // try testMatrixB.set(1, 4, 4.0);
    // try testMatrixB.set(2, 1, 5.0);
    // try testMatrixB.set(2, 2, 6.0);
    // try testMatrixB.set(2, 3, 7.0);
    // try testMatrixB.set(2, 4, 8.0);

    // var resultMatrix = la.multiply(&testMatrixA, &testMatrixB, allocator) catch unreachable;
    // try testMatrixA.print(stdout);
    // try stdout.print("-------------------------------\n", .{});
    // try testMatrixB.print(stdout);
    // try stdout.print("-------------------------------\n", .{});
    // try resultMatrix.print(stdout);

    // var expectedRowVector = la.Vector.zeroes(allocator, 2) catch unreachable;
    // try expectedRowVector.set(1, 5.0);
    // try expectedRowVector.set(2, 6.0);

    // var gottenRow = la.getRow(&testMatrixA, 3, allocator) catch unreachable;
    // try testMatrixA.print(stdout);
    // try stdout.print("-------------------------------\n", .{});
    // try gottenRow.print(stdout);

}


pub fn main() !void {
    try run();
    if (gpallocator.detectLeaks()) {
        std.log.warn("😡😡😡😡😡😡😡 grr try not leaking next time", .{});
    }
}