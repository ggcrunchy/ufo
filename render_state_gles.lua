-- Modules --
local ffi = require("ffi")
--local gl  = require("ffi/OpenGLES2")
local xforms = require("transforms_gles")

-- Exports --
local M = {}

-- --
local MVP = NewMatrix()

-- --
local MatrixSize = ffi.sizeof(src)

--
local CopyMatrix (dst, src)
	ffi.copy(dst, src, MatrixSize)
end

--
local function NewMatrix ()
	local mat = xforms.New()

	xforms.MatrixLoadIdentity(mat)

	return mat
end

--- DOCME
function M.GetModelViewProjection (mvp)
	CopyMatrix(mvp, MVP)
end

-- --
local MV = NewMatrix()

--- DOCME
function M.GetModelView (mv)
	CopyMatrix(mv, MV)
end

-- --
local Proj = NewMatrix()

--- DOCME
function M.GetProjection (proj)
	CopyMatrix(proj, Proj)
end

--
local function ComputeMVP ()
	xforms.MatrixMultiply(MVP, MV, Proj)
end

--- DOCME
-- @param mv
function M.SetModelViewMatrix (mv)
	CopyMatrix(MV, mv)
	ComputeMVP()
end

--- DOCME
-- @param proj
function M.SetProjectionMatrix (proj)
	CopyMatrix(Proj, proj)
	ComputeMVP()
end

-- Export the module.
return M