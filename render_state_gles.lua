-- Modules --
local ffi = require("ffi")
--local gl  = require("ffi/OpenGLES2")
local xforms = require("transforms_gles")

-- Exports --
local M = {}

--
local function NewMatrix ()
	local mat = xforms.New()

	xforms.MatrixLoadIdentity(mat)

	return mat, 0
end

-- --
local MVP, ID_MVP = NewMatrix()

-- --
local MatrixSize = ffi.sizeof(src)

--
local CopyMatrix (dst, src, rval)
	ffi.copy(dst, src, MatrixSize)
end

--- DOCME
function M.GetModelViewProjection (mvp)
	CopyMatrix(mvp, MVP)

	return ID_MVP
end

-- --
local MV, ID_MV = NewMatrix()

--- DOCME
function M.GetModelView (mv)
	CopyMatrix(mv, MV)

	return ID_MV
end

-- --
local Proj, ID_Proj = NewMatrix()

--- DOCME
function M.GetProjection (proj)
	CopyMatrix(proj, Proj)

	return ID_Proj
end

--
local function ComputeMVP ()
	xforms.MatrixMultiply(MVP, MV, Proj)

	ID_MVP = ID_MVP + 1
end

--- DOCME
-- @param mv
function M.SetModelViewMatrix (mv)
	ID_MV = ID_MV + 1

	CopyMatrix(MV, mv)
	ComputeMVP()
end

--- DOCME
-- @param proj
function M.SetProjectionMatrix (proj)
	ID_Proj = ID_Proj + 1

	CopyMatrix(Proj, proj)
	ComputeMVP()
end

-- Export the module.
return M