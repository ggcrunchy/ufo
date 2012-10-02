-- Standard library imports --
local abs = math.abs
local assert = assert
local min = math.min


-- Modules --
local bit = require("bit")
local ffi = require("ffi")
local numeric_ops = require("numeric_ops")

-- Imports --
local band = bit.band
local bnot = bit.bnot
local bor = bit.bor
local CellToIndex = numeric_ops.CellToIndex

--[[
--- module "fringe"
]]
local _M = {}

-- Flags --
local Occupied = 0x1
local OccupiedAbove = 0x2
local OccupiedBelow = 0x4
local OccupiedToLeft = 0x8
local OccupiedToRight = 0x10
local InCache = 0x20

-- Declarations --
ffi.cdef [[
	typedef struct FringeCell {
		struct FringeCell * left, * right;
		struct FringeCell * parent;
		double g;
		double h;
		uint16_t col, row;
		uint32_t flags;
	} FringeCell_t;

	typedef struct {
		uint16_t w, h;
		uint16_t tcol, trow;
		int16_t dc, dr;
		FringeCell_t * fringe;
		FringeCell_t cells[?];
	} FringePathData_t;

	typedef struct {
		uint32_t n;
		struct {
			uint16_t col, row;
		} cells[?];
	} FringePath_t;

	typedef struct {
		uint16_t w, h;
		uint8_t flags[?];
	} Zone_t;
]]

local PathDataCT = ffi.typeof("FringePathData_t")
local PathCT = ffi.typeof("FringePath_t")
local ZoneCT = ffi.typeof("Zone_t")

-- Sentinel node --
local NullNode = ffi.new("FringeCell_t[1]")

-- Adds a node to the open list
local function NewNode (path, node)
	node.flags = bor(node.flags, InCache)
	node.left = NullNode
	node.right = NullNode

	local dc = path.tcol - node.col
	local dr = path.trow - node.row
	local diag = min(abs(dc), abs(dr))
	local cross = abs(dc * path.dr - dr * path.dc)

	node.h = (1.414 * diag + (abs(dc) + abs(dr) - 2 * diag)) + cross * .001
end

--
local function AddAfter (prev, node)
	prev.right.left = node

	node.left = prev
	node.right = prev.right
	prev.right = node
end

--
local function RemoveNode (path, node)
	if node == path.fringe then
		path.fringe = node.right
	end

	node.left.right = node.right
	node.right.left = node.left

	--
	node.left = node
end

--
local function FormSuccessor (path, node, succ)
	local new_cost = node.g + 1

	-- If the node is unused, add it to the open list as a child of the generator node.
	if band(succ.flags, InCache) == 0 then
		NewNode(path, succ)
	elseif new_cost >= succ.g then
		return
	elseif succ.left ~= succ then
		RemoveNode(path, succ)
	end

	succ.parent = node
	succ.g = new_cost

	AddAfter(node, succ)
end

--
local function GenerateSuccessors (path, node)
	if band(node.flags, OccupiedToLeft) == 0 then
		FormSuccessor(path, node, node - 1)
	end

	if band(node.flags, OccupiedToRight) == 0 then
		FormSuccessor(path, node, node + 1)
	end

	if band(node.flags, OccupiedAbove) == 0 then
		FormSuccessor(path, node, node - path.w)
	end

	if band(node.flags, OccupiedBelow) == 0 then
		FormSuccessor(path, node, node + path.w)
	end
end

-- Builds a path from start to finish
local function BuildPath (current)
	local n = current.g + 1 -- TODO: This will break down with different costs; abstract path behind backwards table?
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

	-- Add the initial node to kick off the search.
	NewNode(path, path.cells + findex)

	path.fringe = path.cells + findex

	-- Iterate until either the open list is empty or the best node is the goal. In the
	-- latter case, build up the path
	local flimit = path.fringe.h

	repeat
		local node = path.fringe
		local fmin = 1 / 0

		repeat
			if node == path.cells + tindex then
				return BuildPath(node), path
			end

			local f = node.g + node.h

			if f > flimit then
				fmin = min(f, fmin)
			else
				GenerateSuccessors(path, node)
				RemoveNode(path, node)
			end

			node = node.right
		until node == NullNode

		flimit = fmin
	until path.fringe == NullNode

	return false, path
end

--
local function IsClosed (node)
	return node.left == node
end

function _M.IsClosed (path, index)
	return IsClosed(path.cells + index)
end

function _M.IsOpen (path, index)
	local node = path.cells + index

	return not (IsClosed(node) or band(node.flags, InCache) == 0)
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