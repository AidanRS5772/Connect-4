const std = @import("std");

const Board = struct {
    // Stores Data of the board as a u84 where every 2 bits repersents an i2
    // b00 -> 0 ->  Empty
    // b01 -> 1 -> Player Peice
    // b11 -> -1 -> Advisary Peice
    // Position of i2 is mapped as 6*col + row for every 2 bits

    data: std.PackedIntArray(i2, 42),

    pub fn init() Board {
        return Board{ .data = std.PackedIntArray(i2, 42).initAllTo(0) };
    }

    // non mutable setter
    // sets the data of an i2 in the proper col pushing it to the first zero
    // throws error if attempting to push to position that is already set or full column
    pub fn set(self: *Board, col: usize, player: i2) !void {
        if (col >= 7) return error.OutOfBounds;

        const start_idx: usize = col * 6;
        var idx = start_idx;
        while (self.data.get(idx) != 0) : (idx += 1) {
            if ((idx - start_idx) >= 6) return error.ColumnFull;
        }

        self.data.set(idx, player);
    }

    // gets data at some col and row
    // errors if col or row are out of bounds
    pub fn get(self: Board, col: u7, row: u7) !i2 {
        if ((col >= 7) or (row >= 6)) return error.OutOfBounds;
        return self.data.get(6 * col + row);
    }

    // player(?i2): connect of -1 or 1
    // start of connect path(?u7): the shift amount to get to that position
    // direction(?u7): shift amount to get to the next peice on path
    // length of path: amount of shifts until shifts are no longer on the path
    // index:(?u7) of last peice in connect
    const Connect_Data = struct {
        player: i2,
        start: usize,
        dir: usize,
        len: usize,
        idx: usize,
    };

    // finds all connects of a specific size and returns all the info of all the connects
    pub fn all_connects(self: Board, a: std.mem.Allocator, sz: usize) !std.ArrayList(Connect_Data) {
        var connects = std.ArrayList(Connect_Data).init(a);

        // check columns
        for (0..7) |i| {
            var cnt: usize = 0;
            var crnt_bit2: i2 = 0;
            for (0..6) |j| {
                const bit2 = self.data.get(6 * i + j);
                if (bit2 == 0) {
                    break;
                }

                if (crnt_bit2 == bit2) {
                    cnt += 1;
                } else {
                    crnt_bit2 = bit2;
                    cnt = 1;
                }

                if (cnt >= sz) {
                    const con_data = Connect_Data{
                        .player = crnt_bit2,
                        .start = 6 * i,
                        .dir = 1,
                        .len = 6,
                        .idx = j,
                    };
                    try connects.append(con_data);
                }
            }
        }

        // check rows
        for (0..6) |i| {
            var cnt: usize = 0;
            var crnt_bit2: i2 = 0;
            for (0..7) |j| {
                const bit2 = self.data.get(i + 6 * j);
                if (bit2 == 0) {
                    cnt = 0;
                    crnt_bit2 = 0;
                    continue;
                }

                if (crnt_bit2 == bit2) {
                    cnt += 1;
                } else {
                    crnt_bit2 = bit2;
                    cnt = 1;
                }

                if (cnt >= sz) {
                    const con_data = Connect_Data{
                        .player = crnt_bit2,
                        .start = i,
                        .dir = 6,
                        .len = 7,
                        .idx = j,
                    };
                    try connects.append(con_data);
                }
            }
        }

        //check low to high diagonals part 1
        for (0..3) |i| {
            var cnt: usize = 0;
            var crnt_bit2: i2 = 0;
            for (0..(6 - i)) |j| {
                const bit2 = self.data.get(i + 7 * j);
                if (bit2 == 0) {
                    cnt = 0;
                    crnt_bit2 = 0;
                    continue;
                }

                if (crnt_bit2 == bit2) {
                    cnt += 1;
                } else {
                    crnt_bit2 = bit2;
                    cnt = 1;
                }

                if (cnt >= sz) {
                    const con_data = Connect_Data{
                        .player = crnt_bit2,
                        .start = i,
                        .dir = 7,
                        .len = 6 - i,
                        .idx = j,
                    };
                    try connects.append(con_data);
                }
            }
        }

        //check low to high diagonals part 2
        for (1..4) |i| {
            var cnt: usize = 0;
            var crnt_bit2: i2 = 0;
            for (0..(7 - i)) |j| {
                const bit2 = self.data.get(6 * i + 7 * j);
                if (bit2 == 0) {
                    cnt = 0;
                    crnt_bit2 = 0;
                    continue;
                }

                if (crnt_bit2 == bit2) {
                    cnt += 1;
                } else {
                    crnt_bit2 = bit2;
                    cnt = 1;
                }

                if (cnt >= sz) {
                    const con_data = Connect_Data{
                        .player = crnt_bit2,
                        .start = 6 * i,
                        .dir = 7,
                        .len = 7 - i,
                        .idx = j,
                    };
                    try connects.append(con_data);
                }
            }
        }

        //check high to low diagonals part 1
        for (3..6) |i| {
            var cnt: usize = 0;
            var crnt_bit2: i2 = 0;
            for (0..(i + 1)) |j| {
                const bit2 = self.data.get(i + 5 * j);
                if (bit2 == 0) {
                    cnt = 0;
                    crnt_bit2 = 0;
                    continue;
                }

                if (crnt_bit2 == bit2) {
                    cnt += 1;
                } else {
                    crnt_bit2 = bit2;
                    cnt = 1;
                }

                if (cnt >= sz) {
                    const con_data = Connect_Data{
                        .player = crnt_bit2,
                        .start = i,
                        .dir = 5,
                        .len = i + 1,
                        .idx = j,
                    };
                    try connects.append(con_data);
                }
            }
        }

        //check high to low diagonals part 2
        for (1..4) |i| {
            var cnt: usize = 0;
            var crnt_bit2: i2 = 0;
            for (0..(7 - i)) |j| {
                const bit2 = self.data.get(5 + 6 * i + 5 * j);
                if (bit2 == 0) {
                    cnt = 0;
                    crnt_bit2 = 0;
                    continue;
                }

                if (crnt_bit2 == bit2) {
                    cnt += 1;
                } else {
                    crnt_bit2 = bit2;
                    cnt = 1;
                }

                if (cnt >= sz) {
                    const con_data = Connect_Data{
                        .player = crnt_bit2,
                        .start = 5 + 6 * i,
                        .dir = 5,
                        .len = 7 - i,
                        .idx = j,
                    };
                    try connects.append(con_data);
                }
            }
        }

        return connects;
    }

    // finds all columns that stop win in next move for human
    pub fn stop_wins(self: Board, connects: std.ArrayList(Connect_Data)) ?[7]bool {
        var cols = std.mem.zeroes([7]bool);
        var state = false;
        for (connects.items) |cd| {
            if (cd.player == -1) break;

            if (cd.idx >= 3) {
                const col:usize = (cd.start + cd.dir * (cd.idx - 3))/6;
                const row:usize = (cd.start + cd.dir * (cd.idx - 3))%6;
                if (self.data.get(6*col+row) == 0){
                    if (row != 0){
                        if (self.data.get(6*col+row-1) != 0){
                            state = true;
                            cols[col] = true;
                        }
                    }else{
                        state = true;
                        cols[col] = true;
                    }
                }
            }

            if ((cd.idx + 1) < cd.len) {
                const col:usize = (cd.start + cd.dir * (cd.idx + 1))/6;
                const row:usize = (cd.start + cd.dir * (cd.idx + 1))%6;
                if (self.data.get(6*col+row) == 0){
                    if (row != 0){
                        if (self.data.get(6*col+row-1) != 0){
                            state = true;
                            cols[col] = true;
                        }
                    }else{
                        state = true;
                        cols[col] = true;
                    }
                }
            }
        }

        if (state) return cols else return null;
    }

    // finds the first column that making a move at would result in a win and null if there is no such column
    pub fn find_win(self: Board, connects: std.ArrayList(Connect_Data), player: i2) ?usize {
        for (connects.items) |cd| {
            if (cd.player == player) break;

            if (cd.idx >= 3) {
                const col:usize = (cd.start + cd.dir * (cd.idx - 3))/6;
                const row:usize = (cd.start + cd.dir * (cd.idx - 3))%6;
                if (self.data.get(6*col+row) == 0){
                    if (row != 0){
                        if (self.data.get(6*col+row-1) != 0){
                            return col;
                        }
                    }else{
                        return col;
                    }
                }
            }

            if ((cd.idx + 1) < cd.len) {
                const col:usize = (cd.start + cd.dir * (cd.idx + 1))/6;
                const row:usize = (cd.start + cd.dir * (cd.idx + 1))%6;
                if (self.data.get(6*col+row) == 0){
                    if (row != 0){
                        if (self.data.get(6*col+row-1) != 0){
                            return col;
                        }
                    }else{
                        return col;
                    }
                }
            }
        }

        return null;
    }

    // finds all columns that result in a win
    pub fn find_all_wins(self: Board, connects: std.ArrayList(Connect_Data), player: i2) [7]bool {
        var cols = std.mem.zeroes([7]bool);
        for (connects.items) |cd| {
            if (cd.player == player) break;

            if (cd.idx >= 3) {
                const col:usize = (cd.start + cd.dir * (cd.idx - 3))/6;
                const row:usize = (cd.start + cd.dir * (cd.idx - 3))%6;
                if (self.data.get(6*col+row) == 0){
                    if (row != 0){
                        if (self.data.get(6*col+row-1) != 0){
                            cols[col] = true;
                        }
                    }else{
                        cols[col] = true;
                    }
                }
            }

            if ((cd.idx + 1) < cd.len) {
                const col:usize = (cd.start + cd.dir * (cd.idx + 1))/6;
                const row:usize = (cd.start + cd.dir * (cd.idx + 1))%6;
                if (self.data.get(6*col+row) == 0){
                    if (row != 0){
                        if (self.data.get(6*col+row-1) != 0){
                            cols[col] = true;
                        }
                    }else{
                        cols[col] = true;
                    }
                }
            }
        }

        return cols;
    }

    //returns all available columns to make a move
    pub fn available_col(self: Board) [7]bool {
        var out: [7]bool = undefined;
        for (0..7) |i| {
            if (self.data.get(5+6*i) == 0) {
                out[i] = true;
            } else {
                out[i] = false;
            }
        }

        return out;
    }

    // visually displays board
    pub fn display_board(self: Board) void {
        std.debug.print("\n", .{});
        var i = 5;
        while (i > 0) : (i -= 1){
            for (0..7) |j|{
                const val = self.data.get(i+6*j);
                if (val == -1){
                    std.debug.print(" {}", .{val});
                }else{
                    std.debug.print("  {}", .{val});
                }
            }
        }
    }
};

pub fn Queue(comptime Child: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            data: Child,
            next: ?*Node,
        };
        a: *std.mem.Allocator,
        start: ?*Node,
        end: ?*Node,
        len: usize,

        pub fn init(a: *std.mem.Allocator) This {
            return This{
                .a = a,
                .start = null,
                .end = null,
                .len = 0,
            };
        }

        pub fn deinit(this: *This) void {
            var current = this.start;
            while (current) |node| {
                const next = node.next;
                this.a.destroy(node);
                current = next;
            }
            this.start = null;
            this.end = null;
            this.len = 0;
        }

        pub fn in(this: *This, value: Child) !void {
            const node = try this.a.create(Node);
            node.* = .{ .data = value, .next = null };
            if (this.end) |end| end.next = node else this.start = node;
            this.end = node;
            this.len += 1;
        }

        pub fn out(this: *This) !Child {
            const start = this.start orelse return error.QueueIsEmpty;
            defer this.a.destroy(start);
            if (start.next) |next|
                this.start = next
            else {
                this.start = null;
                this.end = null;
            }
            this.len -= 1;
            return start.data;
        }

        pub fn transfer(dest: *This, src: *This) !void {
            // Ensure dest is empty
            if (dest.len != 0) {
                return error.DesinationIsNotEmpty;
            }

            // Transfer pointers
            dest.start = src.start;
            dest.end = src.end;
            dest.len = src.len;

            // Nullify src pointers and reset length
            src.start = null;
            src.end = null;
            src.len = 0;
        }
    };
}

const GameTree = struct {
    const Node = struct {
        baord: Board,
        parent: ?*Node,
        children: std.ArrayList(*Node),

        pub fn init(a: *std.mem.Allocator, board: Board, parent: ?*Node) !*Node {
            const node_ptr = try a.create(Node);
            node_ptr.* = Node{
                .baord = board,
                .parent = parent,
                .children = std.ArrayList(*Node).init(a.*),
            };
            return node_ptr;
        }

        pub fn deinit(self: *Node, a: *std.mem.Allocator) void {
            for (self.children.items) |child| {
                child.deinit(a);
            }
            self.children.deinit();
            a.destroy(self);
        }
    };

    root: *Node,
    a: *std.mem.Allocator,

    pub fn init(a: *std.mem.Allocator) !GameTree {
        return GameTree{
            .root = try Node.init(a, Board.init(), null),
            .a = a,
        };
    }

    pub fn deinit(self: *GameTree) void {
        self.root.deinit(self.a);
    }

    pub fn make(self: *GameTree, max_order: usize) !void {
        var out_q = Queue(*Node).init(self.a);
        defer out_q.deinit();
        try out_q.in(self.root);

        var order: usize = 0; // level of the tree
        var player: i2 = 1; // player making moves
        std.debug.print("level || # of nodes\n______||___________\n------||-----------\n", .{});
        while (order < max_order) {
            var in_q = Queue(*Node).init(self.a);
        
            while (out_q.len > 0){
                var crnt = try out_q.out();

                // Control flow for different constructions at different levels
                if (order < 5) { // No columns will be filled nor wins or almost wins in the first 5 orders
                    // control flow for who is moving
                    if (player == 1) { // human can make any move
                        for (0..7) |i| {
                            var new_board = crnt.baord;
                            try new_board.set(@intCast(i), player);
                            const child = try Node.init(self.a, new_board, crnt);
                            try crnt.children.append(child);
                            try in_q.in(child);
                        }
                    } else { // limit early AI moves to middle three columns
                        for (2..5) |i| {
                            var new_board = crnt.baord;
                            try new_board.set(@intCast(i), player);
                            const child = try Node.init(self.a, new_board, crnt);
                            try crnt.children.append(child);
                            try in_q.in(child);
                        }
                    }
                } else { // checks for wins, almost wins, and available columns
                    const connects = try crnt.baord.all_connects(self.a.*, 3);
                    defer connects.deinit();

                    // control flow for who is moving
                    if (player == 1) {
                        const win_cols = crnt.baord.find_all_wins(connects, player);
                        const avail_cols = crnt.baord.available_col();
                        for (0..7) |i| {
                            if (avail_cols[i]) { // check if col is available
                                var new_board = crnt.baord;
                                try new_board.set(@intCast(i), player);
                                const child = try Node.init(self.a, new_board, crnt);
                                try crnt.children.append(child);
                                if (!win_cols[i]) { // no need to add to queue if the board is a winner
                                    try in_q.in(child);
                                }
                            }
                        }
                    } else {
                        // check if there is a winning col
                        const win_col = crnt.baord.find_win(connects, player);
                        if (win_col != null) { // check if there is a winning move
                            var new_board = crnt.baord;
                            try new_board.set(win_col.?, player);
                            const child = try Node.init(self.a, new_board, crnt);
                            try crnt.children.append(child);
                            continue;
                        }

                        // check for moves that stop human from winning
                        const stop_win_cols_opt = crnt.baord.stop_wins(connects);
                        if (stop_win_cols_opt != null) {
                            const stop_win_cols = stop_win_cols_opt.?;
                            for (0..7) |i| {
                                if (stop_win_cols[i]) {
                                    var new_board = crnt.baord;
                                    try new_board.set(@intCast(i), player);
                                    const child = try Node.init(self.a, new_board, crnt);
                                    try crnt.children.append(child);
                                    try in_q.in(child);
                                }
                            }
                            continue;
                        }

                        //no winner or blockers
                        const avail_cols = crnt.baord.available_col();
                        for (0..7) |i| {
                            if (avail_cols[i]) { // check if col is available
                                var new_board = crnt.baord;
                                try new_board.set(@intCast(i), player);
                                const child = try Node.init(self.a, new_board, crnt);
                                try crnt.children.append(child);
                                try in_q.in(child);
                            }
                        }
                    }
                }
            }
            
            try out_q.transfer(&in_q);
            order += 1;
            player *= -1;
            std.debug.print("{}     || {}\n", .{ order,  out_q.len});
        }
    }
};

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var tree = try GameTree.init(&allocator);
    defer tree.deinit();
    try tree.make(7);
}
