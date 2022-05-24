-- Copyright (c) 2020, The Pallene Developers
-- Pallene is licensed under the MIT license.
-- Please refer to the LICENSE and AUTHORS files for details
-- SPDX-License-Identifier: MIT

local util = require "pallene.util"

-- @param xs An ordered sequence of comparable items
-- @param v A value comparable to the items in the list
-- @return The position of the first occurrence of `v` in the sequence or the
-- position of the first item greater than `v` in the sequence, otherwise.
-- Inserting `v` at the returned position will always keep the sequence ordered.
local function binary_search(xs, v)
    -- Invariants:
    --   1 <= lo <= hi <= #xs + 1
    --   xs[i] < v , if i < lo
    --   xs[i] >= v, if i >= hi
    local lo = 1
    local hi = #xs + 1
    while lo < hi do
        -- Average, rounded down (lo <= mid < hi)
        -- Lua's logical right shift works here even if the addition overflows
        local mid = (lo + hi) >> 1
        if xs[mid] < v then
            lo = mid + 1
        else
            hi = mid
        end
    end
    return lo
end

local newline_cache = setmetatable({}, { __mode = "k" })

-- Converts an Lpeg file position into more familiar line and column numbers.
--
-- @param subject The contents of an entire source code file
-- @param pos A position in this file, as an absolute integer index
-- @return The line and column number at the specified position.
local function get_line_number(subject, pos)
    local new_lines
    if newline_cache[subject] then
        new_lines = newline_cache[subject]
    else
        new_lines = {}
        for n in subject:gmatch("()\n") do
            table.insert(new_lines, n)
        end
        newline_cache[subject] = new_lines
    end
    local line = binary_search(new_lines, pos)
    local col  = pos - (new_lines[line - 1] or 0)
    return line, col
end

--
-- A datattype representing a point in a source code file
--
local Location = util.Class()

function Location:init(file_name, line, col, pos)
    self.file_name = file_name
    self.line = line
    self.col = col
    self.pos = pos
end

function Location.from_pos(file_name, source, pos) -- alternate constructor
    local line, col = get_line_number(source, pos)
    return Location.new(file_name, line, col, pos)
end

function Location:show_line()
    return string.format("%s:%d", self.file_name, self.line)
end

function Location:show_line_col()
    return string.format("%s:%d:%d", self.file_name, self.line, self.col)
end

function Location:__tostring()
    return string.format("%d:%d", self.line, self.col)
end

function Location:format_error(fmt, ...)
    return self:show_line_col() .. ": " .. string.format(fmt, ...)
end

return Location
