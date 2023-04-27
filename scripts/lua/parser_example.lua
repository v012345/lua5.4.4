require("bytedump")

Chess = {
    board = {
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    X = 8,
    Y = 8,
    queen = 1,
}

function Chess:getPiece(x, y)
    return self.board[x][y]
end

function Chess:getQueenY(x)
    for i, v in ipairs(self.board[x]) do
        if v == 1 then
            return i
        end
    end
    return 0
end

function Chess:setPiece(x, y, piece)
    self.board[x][y] = piece
end

function Chess:set(x, y)
    if x > 8 then
        return
    end
    if y > 8 then
        local _y = self:getQueenY(x - 1)
        if _y ~= 0 then
            self:setPiece(x - 1, _y, 0)
            self:set(x - 1, _y + 1)
            return
        else
            return
        end
    end
    self:setPiece(x, y, 1)
    Chess:printBoard()
    if Chess:canAttack(x, y) then
        self:setPiece(x, y, 0)
        self:set(x, y + 1)
    else
        self:set(x + 1, 1)
    end
end

function Chess:canAttack(x, y)
    if self:getPiece(x, y) ~= self.queen then
        print("not a queen")
        return false
    end
    local vecs = {
        { 1,  1 },
        { 1,  -1 },
        { -1, 1 },
        { -1, -1 },
        { 0,  1 },
        { 0,  -1 },
        { 1,  0 },
        { -1, 0 },
    }
    for _, vec in ipairs(vecs) do
        local _x = x + vec[1]
        local _y = y + vec[2]

        while (_x > 0 and _x <= self.X) and (_y > 0 and _y <= self.Y) do
            if self:getPiece(_x, _y) == self.queen then
                return true
            end
            _x = _x + vec[1]
            _y = _y + vec[2]
        end
    end
    return false
end

function Chess:printBoard()
    print("=========================")
    for i = 1, 8 do
        print(table.concat(self.board[i], " "))
    end
end

Chess:set(1, 1)
-- Chess:setPiece(1, 1, 1)
-- Chess:setPiece(2, 2, 1)
-- print(Chess:canAttack(2, 2))
Chess:printBoard()


Bytedump:dump(GetOpCodes())
