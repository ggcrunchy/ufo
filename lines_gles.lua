-- Modules --
local ffi = require("ffi")
local gl  = require("ffi/OpenGLES2")
local shader_helper = require("lib.shader_helper")
local xforms = require("transforms_gles")

--[[
Line shader?
-- Identity -> loc_mvp
	gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, 0, 0, (void*)lVerts)
	gl.glDrawArrays(gl.GL_LINES, 0, objects[2].nEdges*2)
]]