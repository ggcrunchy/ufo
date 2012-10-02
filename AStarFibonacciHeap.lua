-- Standard library imports --
local abs = math.abs
local assert = assert
local min = math.min

-- Conditional module --
local which_heap = "fibonacci_heap"

-- Modules --
local bit = require("bit")
local ffi = require("ffi")
local heap = require(which_heap)
local numeric_ops = require("numeric_ops")

-- Imports --
local band = bit.band
local bnot = bit.bnot
local bor = bit.bor
local bxor = bit.bxor
local CellToIndex = numeric_ops.CellToIndex
local DecreaseKey = heap.DecreaseKey
local DeleteMin = heap.DeleteMin
local FindMin = heap.FindMin
local Insert_UserNode = heap.Insert_UserNode
local IsEmpty = heap.IsEmpty
local New = heap.New

--[[
--- module "astar"
]]
local _M = {}

-- Flags --
local Occupied = 0x1
local OccupiedAbove = 0x2
local OccupiedBelow = 0x4
local OccupiedToLeft = 0x8
local OccupiedToRight = 0x10
local InOpen = 0x20
local InClosed = 0x40
local InUse = bor(InOpen, InClosed)

-- Declaration parts --
local CellParts, OtherParts = "", ""

if which_heap == "fibonacci_heap" then
	CellParts = "struct AStarCell * pparent;"
	OtherParts = "int degree; bool marked;"
end

-- Declarations --
local CDef = [[
	typedef struct AStarCell {
		struct AStarCell * left, * right;
		struct AStarCell * parent, * child;
]] .. CellParts .. [[
		double g;
		double h;
		double key;
]] .. OtherParts .. [[
		uint16_t col, row;
		uint32_t flags;
	} AStarCell_t;

	typedef struct {
		uint16_t w, h;
		uint16_t tcol, trow;
		int16_t dc, dr;
		AStarCell_t cells[?];
	} AStarPathData_t;

	typedef struct {
		uint32_t n;
		struct {
			uint16_t col, row;
		} cells[?];
	} AStarPath_t;

	typedef struct {
		uint16_t w, h;
		uint8_t flags[?];
	} Zone_t;
]]

ffi.cdef(CDef)

local PathDataCT = ffi.typeof("AStarPathData_t")
local PathCT = ffi.typeof("AStarPath_t")
local ZoneCT = ffi.typeof("Zone_t")

-- Adds a node to the open list
local function InsertNode (H, path, node, g, parent)
	local dc = path.tcol - node.col
	local dr = path.trow - node.row

	node.flags = bor(node.flags, InOpen)
	node.parent = parent
	node.g = g

	local diag = min(abs(dc), abs(dr))
	local cross = abs(dc * path.dr - dr * path.dc)

	node.h = (1.414 * diag + (abs(dc) + abs(dr) - 2 * diag)) + cross * .001

	Insert_UserNode(H, g + node.h, node)
end

--
local function FormSuccessor (H, path, node, succ)
	local new_cost = node.g + .5

	-- If the node is unused, add it to the open list as a child of the generator node.
	if band(succ.flags, InUse) == 0 then
		InsertNode(H, path, succ, new_cost, node)

	-- Otherwise, if the generator node is closer to the goal than the successor node, make
	-- the latter a child of the generator and update its cost. Propagate the new costs to
	-- the successor node's neighbors.
	elseif new_cost < succ.g and band(succ.flags, InOpen) ~= 0 then
		succ.g = new_cost
		succ.parent = node

		DecreaseKey(H, succ, new_cost + succ.h)
	end
end

--
local function GenerateSuccessors (H, path, node)
	if band(node.flags, OccupiedToLeft) == 0 then
		FormSuccessor(H, path, node, node - 1)
	end

	if band(node.flags, OccupiedToRight) == 0 then
		FormSuccessor(H, path, node, node + 1)
	end

	if band(node.flags, OccupiedAbove) == 0 then
		FormSuccessor(H, path, node, node - path.w)
	end

	if band(node.flags, OccupiedBelow) == 0 then
		FormSuccessor(H, path, node, node + path.w)
	end
end

-- Builds a path from start to finish
local function BuildPath (current)
	local n = current.g * 2 + 1 -- TODO: This will break down with different costs; abstract path behind backwards table?
	local path = PathCT(n, n)

	for i = 1, path.n do
		path.cells[path.n - i].col = current.col
		path.cells[path.n - i].row = current.row

		current = current.parent
	end

	return path
end

---
-- @param zone
-- @param fcol
-- @param frow
-- @param tcol
-- @param trow
-- @return
function _M.GeneratePath (zone, fcol, frow, tcol, trow)
	assert(fcol >= 1 and fcol <= zone.w, "Invalid 'from' column")
	assert(frow >= 1 and frow <= zone.h, "Invalid 'from' row")
	assert(tcol >= 1 and tcol <= zone.w, "Invalid 'to' column")
	assert(trow >= 1 and trow <= zone.h, "Invalid 'to' row")

	-- Trivially fail if the start or end cell is in use.
	local findex = CellToIndex(fcol, frow, zone.w) - 1
	local tindex = CellToIndex(tcol, trow, zone.w) - 1

	if band(zone.flags[findex], Occupied) ~= 0 or band(zone.flags[tindex], Occupied) ~= 0 then
		return false
	end

	--
	local path = PathDataCT(zone.w * zone.h, zone.w, zone.h, tcol, trow, tcol - fcol, trow - frow)

	-- Assign coordinates and flags to each cell.
	local index = 0

	for row = 1, zone.h do
		for col = 1, zone.w do
			path.cells[index].col = col
			path.cells[index].row = row
			path.cells[index].flags = zone.flags[index]

			index = index + 1
		end
	end

	-- Add the initial node to kick off the search. Iterate until either the open list is empty.
	local H = New()

	InsertNode(H, path, path.cells + findex, 0)

	repeat
		-- Pull the minimum cost node from the open list.
		local best = FindMin(H)

		DeleteMin(H)

		-- Goal found: build up and return path.
		if best == path.cells + tindex then
			return BuildPath(best), path

		-- Put the node in the closed list and generate its successors.
		else
			best.flags = bxor(best.flags, InUse)
			best.left = nil
			best.right = nil

			GenerateSuccessors(H, path, best)
		end
	until IsEmpty(H)

	return false, path
end

function _M.IsClosed (path, index)
	return band(path.cells[index].flags, InClosed) ~= 0
end

function _M.IsOpen (path, index)
	return band(path.cells[index].flags, InOpen) ~= 0
end

---
-- @param ncols
-- @param nrows
-- @return
function _M.GenerateZone (ncols, nrows)
	assert(ncols > 0, "Invalid column count")
	assert(nrows > 0, "Invalid row count")

	local zone = ZoneCT(ncols * nrows, ncols, nrows)

	-- Mark the left and right sides of the grid as occupied to the left and right,
	-- respectively, i.e. impose boundary conditions.
	local left = 0

	repeat
		zone.flags[left] = bor(zone.flags[left], OccupiedToLeft)

		left = left + ncols

		zone.flags[left - 1] = bor(zone.flags[left - 1], OccupiedToRight)
	until left == ncols * nrows

	-- Mark the top and bottom sides likewise.
	for i = 1, ncols do
		zone.flags[i - 1] = bor(zone.flags[i - 1], OccupiedAbove)
		zone.flags[left - i] = bor(zone.flags[left - i], OccupiedBelow)
	end

	return zone
end

--
local function AuxCellOps (zone, op, col, row)
	local index = CellToIndex(col, row, zone.w) - 1

	op(zone, index, Occupied)

	if col > 1 then
		op(zone, index - 1, OccupiedToRight)
	end

	if col < zone.w then
		op(zone, index + 1, OccupiedToLeft)
	end

	if row > 1 then
		op(zone, index - zone.w, OccupiedBelow)
	end

	if row < zone.h then
		op(zone, index + zone.w, OccupiedAbove)
	end
end

--
local function AuxClear (zone, index, flag)
	zone.flags[index] = band(zone.flags[index], bnot(flag))
end

---
-- @param zone
-- @param col
-- @param row
function _M.ClearCell (zone, col, row)
	AuxCellOps(zone, AuxClear, col, row)
end

---
-- @param zone
-- @param col
-- @param row
-- @return
function _M.GetCell (zone, col, row)
	local index = CellToIndex(col, row, zone.w) - 1

	return band(zone.flags[index], Occupied)
end

--
local function AuxSet (zone, index, flag)
	zone.flags[index] = bor(zone.flags[index], flag)
end

---
-- @param zone
-- @param col
-- @param row
function _M.SetCell (zone, col, row)
	AuxCellOps(zone, AuxSet, col, row)
end

-- Export the module.
return _M