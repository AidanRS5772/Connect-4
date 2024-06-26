const std = @import("std");

const Board = struct {
    // Stores Data of the board as a u84 where every 2 bits repersents an i2
    // b00 -> 0 ->  Empty
    // b01 -> 1 -> Player Peice
    // b11 -> -1 -> Advisary Peice
    // Position of i2 is mapped as 6*col + row for every 2 bits

    data: u84,

    pub fn init() Board {
        return Board{ .data = 0 };
    }

    // non mutable setter
    // sets the data of an i2 in the proper col pushing it to the first zero
    // throws error if attempting to push to position that is already set or full column
    pub fn set(self: *Board, col: u7, player: i2) !void {
        if (col >= 7) {
            return error.OutOfBounds;
        }

        var col_bits: u84 = 0xFFF;
        col_bits <<= 12 * col;
        col_bits &= self.*.data;
        col_bits >>= 12 * col;
        var row: u7 = 0;

        while (col_bits != 0) {
            col_bits >>= 2;
            row += 1;
            if (row > 6) {
                return error.ColumnFull;
            }
        }

        const check = try self.get(col, row);
        if (check != 0) {
            return error.ValueAlreadyExists;
        }

        const uplayer: u2 = @bitCast(player);
        var setter: u84 = @intCast(uplayer);
        setter <<= 12 * col + 2 * row;

        self.*.data |= setter;
    }

    // gets data at some col and row
    // errors if col or row are out of bounds
    pub fn get(self: Board, col: u7, row: u7) !i2 {
        if ((col >= 7) or (row >= 6)) {
            std.debug.print("\nERROR: (col,row) = ({},{})\n", .{ col, row });
            // self.display_board();
            return error.OutOfBounds;
        }
        const bits: u84 = self.data >> (col * 12 + row * 2);
        const bit2: u2 = @intCast(bits & 0b11);
        const val: i2 = @bitCast(bit2);
        return val;
    }

    // finds a connect of pieces of sz length
    // returns the (player, start of connect path, direction, length of path) or all null values if connect was not found
    // player(?i2): connect of -1 or 1
    // start of connect path(?u7): the shift amount to get to that position
    // direction(?u7): shift amount to get to the next peice on path
    // length of path: amount of shifts until shifts are no longer on the path
    pub fn connect(self: Board, sz: usize) struct { ?i2, ?u7, ?u7, ?u7 } {
        //check columns
        var col_idx: u7 = 0;
        while (col_idx < 7) {
            var col_data: u84 = self.data >> col_idx * 12;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..6) |_| {
                const bit2 = col_data & 0b11;
                if (bit2 == 0) {
                    break;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    return .{ player, col_idx * 12, 2, 6 };
                }

                col_data >>= 2;
            }
            col_idx += 1;
        }

        //check rows
        var row_idx: u7 = 0;
        while (row_idx < 6) {
            var row_data: u84 = self.data >> row_idx * 2;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..7) |_| {
                const bit2 = row_data & 0b11;
                if (bit2 == 0) {
                    cnt = 0;
                    crnt_2bit = 0;
                    row_data >>= 12;
                    continue;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    return .{ player, row_idx * 2, 12, 7 };
                }

                row_data >>= 12;
            }

            row_idx += 1;
        }

        // check starting low diagonals
        // part 1
        var l_diag_idx_1: u7 = 0;
        while (l_diag_idx_1 < 3) {
            var diag_bits = self.data >> 2 * l_diag_idx_1;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..(6 - l_diag_idx_1)) |_| {
                const bit2 = diag_bits & 0b11;

                if (bit2 == 0) {
                    cnt = 0;
                    crnt_2bit = 0;
                    diag_bits >>= 14;
                    continue;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    return .{ player, 2 * l_diag_idx_1, 14, 6 - l_diag_idx_1 };
                }

                diag_bits >>= 14;
            }

            l_diag_idx_1 += 1;
        }

        // check starting low diagonals
        // part 2
        var l_diag_idx_2: u7 = 1;
        while (l_diag_idx_2 < 4) {
            var diag_bits = self.data >> 12 * l_diag_idx_2;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..(7 - l_diag_idx_2)) |_| {
                const bit2 = diag_bits & 0b11;

                if (bit2 == 0) {
                    cnt = 0;
                    crnt_2bit = 0;
                    diag_bits >>= 14;
                    continue;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    return .{ player, 12 * l_diag_idx_2, 14, 7 - l_diag_idx_2 };
                }

                diag_bits >>= 14;
            }

            l_diag_idx_2 += 1;
        }

        // check starting high diagonals
        // part 1
        var h_diag_idx_1: u7 = 5;
        while (2 < h_diag_idx_1) {
            var diag_bits = self.data >> 2 * h_diag_idx_1;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..(h_diag_idx_1 + 1)) |_| {
                const bit2 = diag_bits & 0b11;

                if (bit2 == 0) {
                    cnt = 0;
                    crnt_2bit = 0;
                    diag_bits >>= 10;
                    continue;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    return .{ player, 2 * h_diag_idx_1, 10, h_diag_idx_1 + 1 };
                }

                diag_bits >>= 10;
            }

            h_diag_idx_1 -= 1;
        }

        // check starting high diagonals
        // part 2
        var h_diag_idx_2: u7 = 1;
        while (h_diag_idx_2 < 4) {
            var diag_bits = self.data >> 12 * h_diag_idx_1 + 10;
            var cnt: u8 = 0;
            var crnt_2bit: u84 = 0;
            for (0..(7 - h_diag_idx_2)) |_| {
                const bit2 = diag_bits & 0b11;

                if (bit2 == 0) {
                    cnt = 0;
                    crnt_2bit = 0;
                    diag_bits >>= 10;
                    continue;
                }

                if (crnt_2bit != bit2) {
                    crnt_2bit = bit2;
                    cnt = 1;
                } else {
                    cnt += 1;
                }

                if (cnt >= sz) {
                    const ubit2: u2 = @intCast(bit2);
                    const player: i2 = @bitCast(ubit2);
                    return .{ player, 12 * h_diag_idx_1 + 10, 10, 7 - h_diag_idx_2 };
                }

                diag_bits >>= 10;
            }

            h_diag_idx_2 += 1;
        }

        return .{ null, null, null, null };
    }

    // this algorithm checks to see if there is a move that can be done that stops human(1 peices) from winning in the next turn
    // It returns the two possible moves that may do this it returns null for either of the columns if a move there wont stop it
    // It returns null if there is no posibility to win on next turn
    //
    // It checks the column by finding the position before and after 3 ones in a row and then checks if the position below is
    // filled and that position is not filled it then returns the two columns if they are not the same column
    // (case where 3 in a row happen in a column) else it return one and the other as null
    pub fn stop_win(self: Board) !struct { ?u7, ?u7 } {
        const player, const start, const dir, const len = connect(self, 3);
        if (player == null) {
            return .{ null, null };
        } else if (player == -1) {
            return .{ null, null };
        } else {
            // std.debug.print("player: {}, start: {}, dir: {}, len: {}", .{player.?, start.?, dir.?, len.?});
            var cnt: usize = 0;
            var bits = self.data >> start.?;
            var idx: u7 = 0;
            while (idx < len.?) {
                const bit2 = bits & 0b11;
                if (bit2 == 1) {
                    cnt += 1;
                }

                if (cnt >= 3) {
                    break;
                }

                bits >>= dir.?;
                idx += 1;
            }

            var first_col: ?u7 = null;
            if (idx >= 3) {
                var col = start.? / 12;
                var row = (start.? % 12) / 2;
                col += (dir.? * (idx - 3)) / 12;
                row += ((dir.? * (idx - 3)) % 12) / 2;

                var val1: i2 = undefined;
                if (row <= 0) {
                    val1 = 1;
                } else {
                    val1 = try self.get(col, row - 1);
                }
                const val2 = try self.get(col, row);

                if ((val1 != 0) and (val2 == 0)) {
                    first_col = col;
                }
            }

            var second_col: ?u7 = null;
            if ((idx + 1) < len.?) {
                var col = start.? / 12;
                var row = (start.? % 12) / 2;
                col += (dir.? * (idx + 1)) / 12;
                row += ((dir.? * (idx + 1)) % 12) / 2;

                var val1: i2 = undefined;
                if (row <= 0) {
                    val1 = 1;
                } else {
                    val1 = try self.get(col, row - 1);
                }
                const val2 = try self.get(col, row);

                if ((val1 != 0) and (val2 == 0)) {
                    second_col = col;
                }
            }

            if (first_col == second_col) {
                return .{ first_col, null };
            } else {
                return .{ first_col, second_col };
            }
        }
    }

    pub fn find_win(self: Board) !?u7 {
        const player, const start, const dir, const len = connect(self, 3);
        if (player == null) {
            return null;
        } else if (player == 1) {
            return null;
        } else {
            var cnt: usize = 0;
            var bits = self.data >> start.?;
            var idx: u7 = 0;
            while (idx < len.?) {
                const bit2 = bits & 0b11;
                if (bit2 == 3) {
                    cnt += 1;
                }

                if (cnt >= 3) {
                    break;
                }

                bits >>= dir.?;
                idx += 1;
            }

            if (idx >= 3) {
                var col = start.? / 12;
                var row = start.? % 12;
                col += (dir.? * (idx - 3)) / 12;
                row += (dir.? * (idx - 3)) % 12;

                var val1: i2 = undefined;
                if (row <= 0) {
                    val1 = 1;
                } else {
                    val1 = try self.get(col, row - 1);
                }
                const val2 = try self.get(col, row);

                if ((val1 != 0) and (val2 == 0)) {
                    return col;
                }
            }

            if ((idx + 1) < len.?) {
                var col = start.? / 12;
                var row = (start.? % 12) / 2;
                col += (dir.? * (idx + 1)) / 12;
                row += ((dir.? * (idx + 1)) % 12) / 2;

                var val1: i2 = undefined;
                if (row <= 0) {
                    val1 = 1;
                } else {
                    val1 = try self.get(col, row - 1);
                }
                const val2 = try self.get(col, row);

                if ((val1 != 0) and (val2 == 0)) {
                    return col;
                }
            }

            return null;
        }
    }

    //checks if the board has a winner
    pub fn is_win(self: Board) bool {
        const out = connect(self, 4);
        if (out[0] == null) {
            return false;
        } else {
            return true;
        }
    }

    //returns all available columns to make a move
    pub fn available_col(self: Board) [7]bool {
        var out: [7]bool = undefined;
        var bits: u84 = self.data >> 10;
        for (0..7) |i| {
            const bit2: u84 = bits & 0b11;
            if (bit2 == 0) {
                out[i] = true;
            } else {
                out[i] = false;
            }
            bits >>= 12;
        }

        return out;
    }

    // displays bits as list of i2
    pub fn display_bits(self: Board) void {
        var bits: u84 = self.data;

        for (0..42) |_| {
            const bit2: u2 = @intCast(bits & 0b11);
            const val: i2 = @bitCast(bit2);
            std.debug.print("{} ", .{val});
            bits >>= 2;
        }
        std.debug.print("\n", .{});
    }

    // visually displays board
    pub fn display_board(self: Board) void {
        std.debug.print("\n\n", .{});
        var i: u7 = 1;
        while (i < 7) {
            var row: u84 = self.data >> (6 - i) * 2;
            for (0..7) |_| {
                const bit2: u2 = @intCast(row & 0b11);
                const val: i2 = @bitCast(bit2);
                if ((val == 0) or (val == 1)) {
                    std.debug.print("  {}", .{val});
                } else {
                    std.debug.print(" {}", .{val});
                }
                row >>= 12;
            }
            std.debug.print("\n", .{});
            i += 1;
        }
        std.debug.print("\n", .{});
    }
};

const Node = struct {
    // holds the board data in a game tree
    board: Board,
    children: []*Node,
    parent: ?*Node,

    pub fn init(board: Board, parent: ?*Node, a: *std.mem.Allocator) !*Node {
        const out: *Node = try a.create(Node);
        const children = try a.alloc(*Node, 0);
        out.* = Node{
            .board = board,
            .parent = parent,
            .children = children,
        };
        return out;
    }
};

const QNode = struct {
    //holds Nodes that have been added to add children too for BFS construction of tree
    val: *Node,
    next: ?*QNode,
    prev: ?*QNode,

    pub fn init(val: *Node, next: ?*QNode, prev: ?*QNode) QNode {
        return QNode{
            .val = val,
            .next = next,
            .prev = prev,
        };
    }
};

const Q = struct {
    //Queue data structure
    front: ?*QNode,
    back: ?*QNode,
    len: usize,
    a: *std.mem.Allocator,

    pub fn init(a: *std.mem.Allocator) Q {
        return Q{
            .front = null,
            .back = null,
            .len = 0,
            .a = a,
        };
    }

    //enqueue algo to put new entries at the back of the queue
    pub fn in(self: *Q, val: *Node) !void {
        if (self.*.len == 0) {
            const elem = try self.a.create(QNode);
            elem.* = QNode.init(val, null, null);

            self.*.back = elem;
            self.*.front = elem;
        } else if (self.*.len == 1) {
            const elem = try self.a.create(QNode);
            elem.* = QNode.init(val, self.*.front, null);
            self.*.back = elem;
            self.*.front.?.prev = self.*.back;
        } else {
            const elem = try self.a.create(QNode);
            elem.* = QNode.init(val, self.*.back, null);

            self.*.back.?.prev = elem;
            self.*.back = elem;
        }
        self.*.len += 1;
    }

    //dequeue algo to return and destory the front of the queue
    pub fn out(self: *Q) !*Node {
        if (self.*.len == 0) {
            return error.QisEmpty;
        } else if (self.*.len == 1) {
            const old_fb = self.*.front.?;
            const val = old_fb.*.val;
            self.*.front = null;
            self.*.back = null;

            self.a.destroy(old_fb);
            self.*.len -= 1;

            return val;
        } else {
            const old_front = self.*.front.?;
            const val = old_front.*.val;

            self.*.front = old_front.*.prev;
            self.*.front.?.next = null;

            self.a.destroy(old_front);
            self.*.len -= 1;

            return val;
        }
    }
};

const Tree = struct {
    root: *Node,
    a: *std.mem.Allocator,

    //make root of tree
    pub fn init(a: *std.mem.Allocator) !Tree {
        const board: Board = Board.init();
        const root: *Node = try Node.init(board, null, a);
        return Tree{ .root = root, .a = a };
    }

    //finds the proper length of the slice of children nodes by analyzing the top columns of the board struct
    fn count_trues(input: *const [7]bool) usize {
        var cnt: usize = 0;
        for (input) |b| {
            if (b) {
                cnt += 1;
            }
        }

        return cnt;
    }

    // constructs the tree in a BFS way with a level order limiter
    pub fn make(self: *Tree, max_order: usize) !void {
        var q: Q = Q.init(self.*.a);
        var crnt = self.*.root;

        //does initial fill of queue with first children
        var root_children = try self.*.a.alloc(*Node, 7);
        for (0..7) |i| {
            var board = Board.init();
            try board.set(@intCast(i), 1);
            const child = try Node.init(board, crnt, self.*.a);
            root_children[i] = child;
            try q.in(child);
        }
        crnt.children = root_children;

        var player: i2 = -1;
        var lvl_cnt = q.len;
        var order: usize = 1;
        std.debug.print("order: {}, lvl cnt: {}\n", .{ order, lvl_cnt });

        //makes rest tree for levels 1 through 6 with no win condition check
        while ((q.len != 0) and (order < 5) and (order < max_order)) {
            //removes node from queue
            crnt = try q.out();
            lvl_cnt -= 1;

            //makes slice of children for all available moves
            var children_len: usize = 7;

            //heuistically limit first two oposition moves to the three midle column
            var start_col_idx: usize = 0;
            var end_col_idx: usize = 7;
            if ((player == -1) and (order <= 6)) {
                start_col_idx = 2;
                end_col_idx = 5;
                children_len = 3;
            }

            //add children
            var children = try self.*.a.alloc(*Node, children_len);
            var children_idx: usize = 0;
            for (start_col_idx..end_col_idx) |i| {
                var new_board = crnt.board;
                try new_board.set(@intCast(i), player);
                const child = try Node.init(new_board, crnt, self.*.a);
                children[children_idx] = child;
                try q.in(child);
                children_idx += 1;
            }
            crnt.children = children;

            //determines what level order were on by counting the amount of Nodes removed from queue
            if (lvl_cnt == 0) {
                order += 1;
                player *= -1;
                lvl_cnt = q.len;
                std.debug.print("order: {}, lvl cnt: {}\n", .{ order, lvl_cnt });
            }
        }

        //makes rest tree with win conditional generation
        while ((q.len != 0) and (order < max_order)) {
            //removes node from queue
            crnt = try q.out();
            lvl_cnt -= 1;

            //different adding conditions for human and ai
            if (player == 1) {
                //add nodes for human player
                const av_col = crnt.board.available_col();
                const children_len = count_trues(&av_col);
                var children = try self.*.a.alloc(*Node, children_len);
                var children_idx: usize = 0;
                for (0..7) |i| {
                    if (av_col[i]) {
                        var new_board = crnt.board;
                        try new_board.set(@intCast(i), player);
                        const child = try Node.init(new_board, crnt, self.*.a);
                        if (!new_board.is_win()) {
                            //if node is a winner then ther is no need to generate children hence not added to queue
                            try q.in(child);
                        }
                        children[children_idx] = child;
                        children_idx += 1;
                    }
                }
                crnt.children = children;
            } else {
                const win_col = try crnt.board.find_win();
                if (win_col != null) {
                    var new_board = crnt.board;
                    try new_board.set(win_col.?, player);
                    var children = try self.*.a.alloc(*Node, 1);
                    const child = try Node.init(new_board, crnt, self.*.a);
                    children[0] = child;
                    crnt.children = children;

                    if (lvl_cnt == 0) {
                        order += 1;
                        player *= -1;
                        lvl_cnt = q.len;
                        std.debug.print("order: {}, lvl cnt: {}\n", .{ order, lvl_cnt });
                    }

                    continue;
                }

                const stop_win_col1, const stop_win_col2 = try crnt.board.stop_win();
                if ((stop_win_col1 != null) or (stop_win_col2 != null)) {
                    var children_len: usize = 1;
                    if ((stop_win_col1 != null) and (stop_win_col2 != null)) {
                        children_len += 1;
                    }

                    var children = try self.*.a.alloc(*Node, children_len);

                    if (stop_win_col1 != null) {
                        var new_board = crnt.board;
                        try new_board.set(stop_win_col1.?, player);
                        const child = try Node.init(new_board, crnt, self.*.a);
                        try q.in(child);
                        children[0] = child;
                    }

                    if (stop_win_col2 != null) {
                        var new_board = crnt.board;
                        try new_board.set(stop_win_col2.?, player);
                        const child = try Node.init(new_board, crnt, self.*.a);
                        try q.in(child);
                        children[0] = child;
                    }

                    crnt.children = children;

                    if (lvl_cnt == 0) {
                        order += 1;
                        player *= -1;
                        lvl_cnt = q.len;
                        std.debug.print("order: {}, lvl cnt: {}\n", .{ order, lvl_cnt });
                    }

                    continue;
                }

                const av_col = crnt.board.available_col();
                const children_len = count_trues(&av_col);
                var children = try self.*.a.alloc(*Node, children_len);
                var children_idx: usize = 0;
                for (0..7) |i| {
                    if (av_col[i]) {
                        var new_board = crnt.board;
                        try new_board.set(@intCast(i), player);
                        const child = try Node.init(new_board, crnt, self.*.a);
                        try q.in(child);
                        children[children_idx] = child;
                        children_idx += 1;
                    }
                }
                crnt.children = children;
            }

            //determines what level order were on by counting the amount of Nodes removed from queue
            if (lvl_cnt == 0) {
                order += 1;
                player *= -1;
                lvl_cnt = q.len;
                std.debug.print("order: {}, lvl cnt: {}\n", .{ order, lvl_cnt });
            }
        }

        std.debug.print("\nFINISH\n", .{});
    }

    pub fn deinit(self: *Tree) void {
        self.destroy_node(self.*.root);
    }

    fn destroy_node(self: *Tree, node: *Node) void {
        for (node.*.children) |child| {
            self.destroy_node(child);
        }
        self.*.a.destroy(node);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var a = gpa.allocator();
    var tree = try Tree.init(&a);
    try tree.make(6);
    tree.deinit();

    // var b = Board.init();
    // try b.set(2, -1);
    // try b.set(2, -1);
    // try b.set(3, 1);
    // try b.set(3, 1);
    // try b.set(3, 1);

    // const val1 , const val2 = try b.stop_win();
    // if (val1 != null){
    //     std.debug.print("{}", .{val1.?});
    // }
    // if (val2 != null){
    //     std.debug.print("{}", .{val2.?});
    // }
}
