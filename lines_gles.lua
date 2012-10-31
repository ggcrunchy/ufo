-- Standard library imports --
local assert = assert
local type = type

-- Modules --
local ffi = require("ffi")
local gl  = require("ffi/OpenGLES2")
local render_state = require("render_state_gles")
local shader_helper = require("lib.shader_helper")
local types = require("types")
--local xforms = require("transforms_gles")

-- Imports --
local Float3 = types.Float3
local Float4 = types.Float4

-- Exports --
local M = {}

-- --
local MVP = render_state.NewLazyMatrix()

-- --
local Pos = types.Float3A(32)

-- --
local PrevPos = Float3() -- In case we want an "append"...

-- --
local Color = types.Float4A(32)

-- --
local PrevColor = Float4()

-- --
local N = 0

-- --
local DrawBatch

--
local loc_mvp
local loc_pos, loc_color

-- --
local SP = shader_helper.NewShader{
	vs = [[
		attribute mediump vec3 position;
		attribute mediump vec4 color;
		uniform mediump mat4 mvp;

		varying mediump vec4 lcolor;
		
		void main ()
		{
			lcolor = color;

			gl_Position = mvp * vec4(position, 1);
		}
	]],

	fs = [[
		varying mediump vec4 lcolor;

		void main ()
		{
			gl_FragColor = lcolor;
		}
	]],

	on_draw = function(sp)
		if render_state.GetModelViewProjection_Lazy(MVP) then
			sp:BindUniformMatrix(loc_mvp, MVP.matrix[0])
		end
	end,
	
	on_done = function()
		if N > 0 then
			DrawBatch()
		end

		-- Invalidate prev?
	end,

	on_use = function(sp)
	
		-- Set proj = ??
		sp:BindAttributeStream(loc_pos, Pos, 3)
		sp:BindAttributeStream(loc_color, Color, 4)
--	SP:BindUniformMatrix(loc_proj, Proj[0])
--[[
		gl.glDisable(gl.GL_DEPTH_TEST)
		gl.glDisable(gl.GL_CULL_FACE)
		gl.glEnable(gl.GL_TEXTURE_2D)

		local screen = sdl.SDL_GetVideoSurface()

		gl.glViewport(0, 0, screen.w, screen.h)

		xforms.MatrixLoadIdentity(Proj)
		xforms.Ortho(Proj, 0, screen.w, screen.h, 0, 0, 1)

		gl.glActiveTexture(gl.GL_TEXTURE0)
]]
	end
}

loc_mvp = SP:GetUniformByName("mvp")

loc_pos = SP:GetAttributeByName("position")
loc_color = SP:GetAttributeByName("color")

function DrawBatch ()
--	SP:BindAttributeStream(loc_pos, ver, 2)
--	SP:BindAttributeStream(loc_tex, tex, 2)

	SP:DrawArrays(gl.GL_LINES, N * 2)
	-- Prev = Batch[N]?

	N = 0
end

--
local function GetColor (color, def)
	if ffi.istype(Float4, color) then
		return color
	end

	if def == nil then
		def = Float4(1, 1, 1, 1)
	end

	if ffi.istype(Float3, color) then
		ffi.copy(def, color, ffi.sizeof(Float3))

		def[3] = 1

	elseif type(color) == "table" then
		assert(#color == 3 or #color == 4, "Invalid color array")

		for i = 1, #color do
			def[i - 1] = color[i]
		end
	end

	return def
end

--- DOCME
-- @number x1
-- @number y1
-- @number z1
-- @number x2
-- @number y2
-- @number z2
-- @ptable color1
-- @ptable color2
function M.Draw (x1, y1, z1, x2, y2, z2, color1, color2)
	SP:Use()

-- TODO: batching...
--[[
	SP:BindUniformMatrix(loc_proj, Proj[0])
	SP:BindAttributeStream(loc_pos, ver, 2)
	SP:BindAttributeStream(loc_tex, tex, 2)

	SP:DrawArrays(gl.GL_TRIANGLE_STRIP, 4)
]]
	--
	Pos[N * 2], Pos[N * 2 + 1] = Float3(x1, y1, z1), Float3(x2, y2, z2)

	--
	color1 = GetColor(color1)
	color2 = GetColor(color2, color1)

	Color[N * 2], Color[N * 2 + 1] = color1, color2

	--
	N = N + 1

	if N == 32 then
		DrawBatch(SP)
	end
end

-- Export the module.
return M