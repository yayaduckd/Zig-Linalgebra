const std = @import("std");
const testing = std.testing;

pub const LAType = f64;
pub const LASizeType = usize;
pub const equalityTolerance: LAType = 0.000005; 

const stdout = std.io.getStdOut().writer();

pub const Matrix = struct {

    const Self = @This();

    values: []LAType, // Array of values
    m: LASizeType, // Number of rows
    n: LASizeType, // Number of columns
    
    pub fn deinit(self: Self, matrixAllocator: std.mem.Allocator) void {
        matrixAllocator.free(self.values);
    }

    pub fn zeroes(matrixAllocator: std.mem.Allocator, numOfRows: LASizeType, numOfCols: LASizeType) Matrix {
        const matrixSlice: []LAType = matrixAllocator.alloc(LAType, numOfRows * numOfCols) catch @panic("... i ate too much memory sorry");
        // Set LAType to all zeroes
        var i: LASizeType = 0;
        while (i < numOfRows * numOfCols) : (i += 1) {
            matrixSlice[i] = 0.0;
        }

        return Matrix{
            .values = matrixSlice,
            .m = numOfRows,
            .n = numOfCols,
        };
    }

    pub fn identity(matrixAllocator: std.mem.Allocator, dimension: LASizeType) Matrix {
        const matrixSlice: []LAType = matrixAllocator.alloc(LAType, dimension * dimension) catch @panic("... i ate too much memory sorry");
        // Set LAType to all zeroes
        var i: LASizeType = 0;
        while (i < dimension * dimension) : (i += 1) {
            if (i % (dimension + 1) == 0) {
                matrixSlice[i] = 1;
            } else {
                matrixSlice[i] = 0;
            }
        }

        return Matrix {
            .values = matrixSlice,
            .m = dimension,
            .n = dimension,
        };
    }

    pub fn fromSlice(matrixAllocator: std.mem.Allocator, rowNum: LASizeType, colNum: LASizeType, slice: []LAType,) Matrix {
        if (slice.len != rowNum * colNum) {
            @panic("matrix dimensions incorrect");
        }
        const matrixSlice: []LAType = matrixAllocator.alloc(LAType, slice.len) catch @panic("... i ate too much memory sorry");
        std.mem.copy(LAType, matrixSlice, slice);
        return Matrix {
            .values = matrixSlice,
            .m = rowNum,
            .n = colNum,
        };
    }

    pub fn getRowNum(self: Self) LASizeType {
        return self.m;
    }

    pub fn getColNum(self: Self) LASizeType {
        return self.n;
    }

    pub fn get(self: Self, rowNum: LASizeType, colNum: LASizeType) LAType {
        if (rowNum > self.getRowNum()) {
            @panic("MatrixRowSizeError");
        }
        if (colNum > self.getColNum()) {
            @panic("MatrixColSizeError");
        }
        return self.values[(rowNum - 1) * self.getColNum() + (colNum - 1)];
    }

    pub fn set(self: Self, rowNum: LASizeType, colNum: LASizeType, value: LAType) void {
        if (rowNum > self.getRowNum()) {
            @panic("MatrixRowSizeError");
        }
        if (colNum > self.getColNum()) {
            @panic("MatrixColSizeError");
        }
        self.values[(rowNum - 1) * self.getColNum() + (colNum - 1)] = value;
    }

    pub fn print(self: Self, writer: anytype) anyerror!void {
        var m: u8 = 1;
        try writer.print("-------------------------------\n", .{});
        while (m <= self.getRowNum()) : (m += 1) {
            var n: u8 = 1;
            while (n <= self.getColNum()) : (n += 1) {
                try writer.print("{d:.2} ", .{self.get(m, n)});
            }
            try writer.print("\n", .{});
        }
        try writer.print("-------------------------------\n", .{});
    }
};


pub fn getRow(A: *Matrix, rowNum: LASizeType, allocator: std.mem.Allocator) Matrix {
    if (rowNum > A.getRowNum()) {
        @panic("Row too big");
    }

    var row = Matrix.zeroes(allocator, 1, A.getColNum());    
    for (row.values, 0..) |*value, i| {
        value.* = A.get(rowNum, i + 1);
    }
    return row;
}

pub fn getCol(A: *Matrix, colNum: LASizeType, allocator: std.mem.Allocator) Matrix {
    if (colNum > A.getColNum()) {
        @panic("Col too big");
    }

    var col = Matrix.zeroes(allocator, 1, A.getRowNum());
    for (col.values, 0..) |*value, i| {
        value.* = A.get(i + 1, colNum);
    }
    return col;
}


pub fn matrixEquals(a: *const Matrix, b: *const Matrix) bool {
    if (a.getRowNum() != b.getRowNum()) {
        return false;
    }
    if (a.getColNum() != b.getColNum()) {
        return false;
    }
    var i: LASizeType = 1;
    while (i <= a.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= a.getColNum()) : (j += 1) {
            if (!std.math.approxEqAbs(LAType, a.get(i, j), b.get(i, j), 0.005)) {
                return false;
            }
        }
    }
    return true;
}

pub fn augmentWithIdentity(A: *Matrix, allocator: std.mem.Allocator) Matrix {
    if (A.getColNum() != A.getRowNum()) {
        @panic("Matrix now square");
    }
    var newMatrix = Matrix.zeroes(allocator, A.getRowNum(), A.getColNum() * 2);

    var matrixIterator: LASizeType = 0;

    var i: LASizeType = 1;
    while (i <= newMatrix.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= A.getColNum()) : (j += 1) {
            newMatrix.values[matrixIterator] = A.get(i, j);
            matrixIterator += 1;
        }
        j = 1;
        while (j <= A.getColNum()) : (j += 1) {
            if (j == i) {
                newMatrix.values[matrixIterator] = 1;
            }
            // Otherwise the values are already zero
            matrixIterator += 1;
        }
    }
    return newMatrix;
}

// Inverts the Matrix using Gauss-Jordan elimination.
pub fn invert(A: *Matrix, allocator:std.mem.Allocator) Matrix {
    if (A.getRowNum() != A.getColNum()) {
        @panic("Matrix is not square - no inverse exists");
    }

    var augmentedA = augmentWithIdentity(A, allocator);
    gaussJordanElimAugmented(&augmentedA, A.getRowNum(), allocator);
    defer augmentedA.deinit(allocator);
    if (augmentedA.values[augmentedA.values.len - 1] == 0) {
        @panic("Matrix is singular - no inverse exists");
    }

    var invertedA = Matrix.zeroes(allocator, A.getRowNum(), A.getRowNum());
    var inverseIterator: LASizeType = 0;
    var augmentedIterator: LASizeType = invertedA.getColNum();
    while (inverseIterator < invertedA.values.len) : (inverseIterator += 1) {
        invertedA.values[inverseIterator] = augmentedA.values[augmentedIterator];
        if (inverseIterator + 1 % invertedA.getRowNum() == 0) {
            augmentedIterator += invertedA.getRowNum();
        }
        augmentedIterator += 1;
    }
    return invertedA;
}

pub fn add(A: *Matrix, B: *Matrix, allocator: std.mem.Allocator) anyerror!Matrix {
    if (A.getRowNum() != B.getRowNum()) {
        return error.MatrixRowSize;
    }
    if (A.getColNum() != B.getColNum()) {
        return error.MatrixColSize;
    }
    var resultMatrix = Matrix.zeroes(allocator, A.getRowNum(), A.getColNum());
    var i: LASizeType = 1;
    while (i <= A.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= A.getColNum()) : (j += 1) {
            resultMatrix.set(i, j, A.get(i, j) + B.get(i, j));
        }
    }
    return resultMatrix;
}

pub fn subtract(A: *Matrix, B: *Matrix, allocator: std.mem.Allocator) Matrix {
    if (A.getRowNum() != B.getRowNum()) {
        @panic("MatrixRowSizeError");
    }
    if (A.getColNum() != B.getColNum()) {
        @panic("MatrixColSizeError");
    }
    var resultMatrix = Matrix.zeroes(allocator, A.getRowNum(), A.getColNum());
    var i: LASizeType = 1;
    while (i <= A.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= A.getColNum()) : (j += 1) {
            resultMatrix.set(i, j, A.get(i, j) - B.get(i, j));
        }
    }
    return resultMatrix;
}


pub fn dot(a: *Matrix, b: *Matrix) LAType {
    if ((a.getRowNum() != 1) or (b.getRowNum() != 1)) {
        @panic("a or b is not a vector");
    }
    if (a.getRowNum() != b.getRowNum()) {
        @panic("a and b are not the same length");
    }
    var result: LAType = 0;
    for (a.values, 0..) |value, i| {
        result += (value * b.get(1, i + 1));
    }
    return result;
}

pub fn multiply(A: *Matrix, B: *Matrix, allocator: std.mem.Allocator) Matrix {
    if (A.getColNum() != B.getRowNum()) {
        @panic("Matrix wrong size :(");
    }
    var resultMatrix = Matrix.zeroes(allocator, A.getRowNum(), B.getColNum());
    var i: LASizeType = 1;
    while (i <= resultMatrix.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= resultMatrix.getColNum()) : (j += 1) {
            var rowVec: Matrix = getRow(A, i, allocator);
            // defer allocator.free(rowVec);
            var colVec: Matrix = getCol(B, j, allocator);
            // defer allocator.free(colVec);
            resultMatrix.set(i, j, dot(&rowVec, &colVec));
        }
    }
    return resultMatrix;
}

pub fn transpose(A: *Matrix, allocator: std.mem.Allocator) Matrix {
    var AT = Matrix.zeroes(allocator, A.getColNum(), A.getRowNum());
    var i: LASizeType = 1;
    while (i <= AT.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= AT.getColNum()) : (j += 1) {
            AT.set(i, j, A.get(j, i));
        }
    }
    return AT;
}

pub fn scalarMultiply(A: *Matrix, scalar: LAType) void {
    var i: LASizeType = 1;
    while (i <= A.getRowNum()) : (i += 1) {
        var j: LASizeType = 1;
        while (j <= A.getColNum()) : (j += 1) {
            A.set(i, j, A.get(i, j) * scalar);
        }
    }
}

fn findPivotIndexAugmented(A: *Matrix, row: LASizeType, augmentLinePos: LASizeType) LASizeType {
    var i: LASizeType = 1;
    while (i <= augmentLinePos) : (i += 1) {
        const pivot = A.get(row, i);
        if (pivot != 0) {
            return i;
        }
    }
    return i - 1;
}

fn findPivotIndex(A: *Matrix, row: LASizeType) LASizeType {
    return findPivotIndexAugmented(A, row, A.getColNum());
}

fn reduceBySubtraction(A: *Matrix, firstRowNum: LASizeType, augmentLinePos: LASizeType, allocator: std.mem.Allocator) void {
    var i: LASizeType = firstRowNum + 1;
    var pivotRow: Matrix = getRow(A, firstRowNum, allocator);
    defer pivotRow.deinit(allocator);
    
    var pivotIndex = findPivotIndexAugmented(&pivotRow, 1, augmentLinePos);
    var pivot = pivotRow.get(1, pivotIndex);
    if (pivot == 0) {
        return;
    }

    var normalizeFactor: LAType = 1 / pivot;
    while (i <= A.getRowNum()) : (i += 1) {
        var firstRow: Matrix = getRow(A, firstRowNum, allocator);
        defer firstRow.deinit(allocator);
        const rowValueOne: LAType = A.get(i, pivotIndex);
        const scalingFactor: LAType = (rowValueOne / pivot);
        scalarMultiply(&firstRow, scalingFactor);
        var j: LASizeType = 1;
        while (j <= A.getColNum()) : (j += 1) {
            const newVal: LAType = A.get(i, j) - firstRow.get(1, j);
            A.set(i, j, newVal);
        }
    }
    // A.print(stdout) catch unreachable;
    // stdout.print("-------------------------------\n", .{}) catch unreachable;
    scalarMultiply(&pivotRow, normalizeFactor);
    var j: LASizeType = 1;
    while (j <= A.getColNum()) : (j += 1) {
        const newVal: LAType = pivotRow.get(1, j);
        A.set(firstRowNum, j, newVal);
    }
}

// Use Gaussian Elimination to derive the row echelon form.
pub fn gaussElimAugmented(A: *Matrix, augmentLinePos: LASizeType, allocator: std.mem.Allocator) void {
    var i: LASizeType = 1;
    while (i <= A.getRowNum()) : (i += 1) {
        reduceBySubtraction(A, i, augmentLinePos, allocator);
    }
}

pub fn gaussElim(A: *Matrix, allocator: std.mem.Allocator) void {
    gaussElimAugmented(A, A.getColNum(), allocator);
}

fn reduceUp(A: *Matrix, startRow: LASizeType, augmentLinePos: LASizeType, allocator: std.mem.Allocator) void {
    const pivotIndex = findPivotIndexAugmented(A, startRow, augmentLinePos);
    var i: LASizeType = startRow - 1;
    while (i >= 1) : (i -= 1) {
        var pivotRow: Matrix = getRow(A, startRow, allocator);
        defer pivotRow.deinit(allocator);
        scalarMultiply(&pivotRow, A.get(i, pivotIndex));
        var j: LASizeType = pivotIndex;
        while (j <= A.getColNum()) : (j += 1) {
            const newValue: LAType = A.get(i, j) - pivotRow.get(1, j);
            A.set(i, j, newValue);
        }
    }
}

pub fn gaussJordanElimAugmented(A: *Matrix, augmentLinePos: LASizeType, allocator: std.mem.Allocator) void {
    gaussElimAugmented(A, augmentLinePos, allocator);
    var i: LASizeType = A.getRowNum();
    while (i > 1) : (i -= 1) {
        reduceUp(A, i, augmentLinePos, allocator);
    }
}

pub fn gaussJordanElim(A: *Matrix, allocator: std.mem.Allocator) void {
    gaussJordanElimAugmented(A, A.getColNum(), allocator);
}


test "basic matrix functionality" {
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpallocator.allocator();

    var testMatrix = Matrix.zeroes(allocator, 3, 3);

    try testing.expect(testMatrix.getRowNum() == 3);
    try testing.expect(testMatrix.getColNum() == 3);

    try testing.expect(testMatrix.get(2, 2) == 0);

    testMatrix.set(2, 2, 1); // Set the value at row 2, column 2 to 1.0
    
    try testing.expect(testMatrix.get(2, 2) == 1);
    
    scalarMultiply(&testMatrix, 2);
    try testing.expect(std.math.approxEqRel(LAType, testMatrix.get(2, 2), 2, 0.005));
}

test "get row and column" {
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpallocator.allocator();

    var testMatrix = Matrix.zeroes(allocator, 4, 2);
    testMatrix.set(1, 2, 2.0);
    testMatrix.set(2, 1, 3.0);
    testMatrix.set(2, 2, 4.0);
    testMatrix.set(3, 1, 5.0);
    testMatrix.set(3, 2, 6.0);
    testMatrix.set(4, 1, 7.0);
    testMatrix.set(4, 2, 8.0);
    testMatrix.set(1, 1, 1.0);

    var expectedRowVector = Matrix.zeroes(allocator, 1, 2);
    expectedRowVector.set(1, 1, 5.0);
    expectedRowVector.set(1, 2, 6.0);
    var gottenRow = getRow(&testMatrix, 3, allocator);
    try testing.expect(matrixEquals(&gottenRow, &expectedRowVector));

    var expectedColVector = Matrix.zeroes(allocator, 1, 4);
    expectedColVector.set(1, 1, 2.0);
    expectedColVector.set(1, 2, 4.0);
    expectedColVector.set(1, 3, 6.0);
    expectedColVector.set(1, 4, 8.0);
    var gottenCol = getCol(&testMatrix, 2, allocator);
    try testing.expect(matrixEquals(&gottenCol, &expectedColVector));
}

test "matrix addition" {
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpallocator.allocator();
    var testMatrixA = Matrix.zeroes(allocator, 3, 3);
    testMatrixA.set(2, 2, 1.0);
    testMatrixA.set(2, 1, 7.6);
    testMatrixA.set(1, 2, 3.2);
    var testMatrixB = Matrix.zeroes(allocator, 3, 3);
    testMatrixB.set(2, 2, 1.0);
    testMatrixB.set(2, 1, 6.7);
    testMatrixB.set(1, 1, 9.6);

    var resultMatrix = try add(&testMatrixA, &testMatrixB, allocator);
    
    var expectedMatrix = Matrix.zeroes(allocator, 3, 3);
    expectedMatrix.set(2, 2, 2.0);
    expectedMatrix.set(2, 1, 14.3);
    expectedMatrix.set(1, 2, 3.2);
    expectedMatrix.set(1, 1, 9.6);
    
    try testing.expect(matrixEquals(&resultMatrix, &expectedMatrix));
}

test "matrix multiplication" {

    // credit: https://www.khanacademy.org/math/precalculus/x9e81a4f98389efdf:matrices/x9e81a4f98389efdf:multiplying-matrices-by-matrices/e/multiplying_a_matrix_by_a_matrix
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpallocator.allocator();

    var E = Matrix.zeroes(allocator, 2, 2);
    E.set(1, 1, 3);
    E.set(1, 2, 5);
    E.set(2, 1, -1);
    E.set(2, 2, 1);

    var A = Matrix.zeroes(allocator, 2, 3);
    A.set(1, 1, -2);
    A.set(1, 2, 2);
    A.set(1, 3, 3);
    A.set(2, 1, 3);
    A.set(2, 2, 5);
    A.set(2, 3, -2);

    var H = Matrix.zeroes(allocator, 2, 3);
    H.set(1, 1, 9);
    H.set(1, 2, 31);
    H.set(1, 3, -1);
    H.set(2, 1, 5);
    H.set(2, 2, 3);
    H.set(2, 3, -5);
    try testing.expect(matrixEquals(&multiply(&E, &A, allocator), &H));

    var A2 = Matrix.zeroes(allocator, 3, 1);
    A2.set(1, 1, -1);
    A2.set(2, 1, 4);
    A2.set(3, 1, 4);
    var F = Matrix.zeroes(allocator, 1, 2);
    F.set(1, 1, 0);
    F.set(1, 2, -2);
    H = Matrix.zeroes(allocator, 3, 2);
    H.set(1, 1, 0);
    H.set(1, 2, 2);
    H.set(2, 1, 0);
    H.set(2, 2, -8);
    H.set(3, 1, 0);
    H.set(3, 2, -8);
    try testing.expect(matrixEquals(&multiply(&A2, &F, allocator), &H));
    

}

test "matrix transpose" {
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpallocator.allocator();
    var A = Matrix.zeroes(allocator, 2, 3);
    A.set(1, 1, 1);
    A.set(1, 2, 2);
    A.set(1, 3, 3);
    A.set(2, 1, 4);
    A.set(2, 2, 5);
    A.set(2, 3, 6);
    var AT = Matrix.zeroes(allocator, 3, 2);
    AT.set(1, 1, 1);
    AT.set(1, 2, 4);
    AT.set(2, 1, 2);
    AT.set(2, 2, 5);
    AT.set(3, 1, 3);
    AT.set(3, 2, 6);
    try testing.expect(matrixEquals(&transpose(&A, allocator), &AT));

    var B = Matrix.identity(allocator, 700);
    try testing.expect(matrixEquals(&B, &transpose(&B, allocator)));
}
