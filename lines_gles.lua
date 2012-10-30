-- Standard library imports --
local assert = assert
local type = type

-- Modules --
local ffi = require("ffi")
local gl  = require("ffi/OpenGLES2")
local render_state = require("render_state_gles")
local shader_helper = require("lib.shader_helper")
local xforms = require("transforms_gles")

-- Exports --
local M = {}

-- --
local Proj = xforms.New()

-- --
local Pos = ffi.new("float[3][?]", 32)

-- --
local PrevPos = ffi.new("float[3]") -- In case we want an "append"...

-- --
local Color = ffi.new("float[4][?]", 32)

-- --
local PrevColor = ffi.new("float[4]")

-- --
local N = 0

--
local function DrawBatch ()
--	SP:BindAttributeStream(loc_pos, ver, 2)
--	SP:BindAttributeStream(loc_tex, tex, 2)

	SP:DrawArrays(gl.GL_LINES, N * 2)
	-- Prev = Batch[N]?

	N = 0
end

--
local loc_proj
local loc_pos, loc_color

-- --
local SP = shader_helper.NewShader(
	[[
		attribute mediump vec2 position;
		attribute mediump vec4 color;
		uniform mediump mat4 proj;

		varying mediump vec4 lcolor;
		
		void main ()
		{
			lcolor = color;

			gl_Position = proj * vec4(position, 0, 1);
		}
	]],
	[[
		void main ()
		{
			gl_FragColor = lcolor;
		}
	]],
	{
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
)

--
loc_proj = SP:GetUniformByName("proj")

loc_pos = SP:GetAttributeByName("position")
loc_color = SP:GetAttributeByName("color")

--
local function Color (color, def)
	if ffi.istype("float[4]", color) then
		return color
	end

	if def == nil then
		def = ffi.new("float[4]", 1, 1, 1, 1)
	end
	
	if ffi.istype("float[3]", color) then
		ffi.copy(def, color, ffi.sizeof("float[3]"))

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
	Pos[N * 2], Pos[N * 2 + 1] = ffi.new("float[3]", x1, y1, z1), ffi.new("float[3]", x2, y2, z2)

	color1 = Color(color1)
	color2 = Color(color2, color1)
	
	Color[N * 2], Color[N * 2 + 1] = color1, color2
	
	N = N + 1

	if N == 32 then
		DrawBatch()
	end
end

-- Export the module.
return M