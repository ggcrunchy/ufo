-- Standard library imports --
local assert = assert
local type = type

-- Modules --
local ffi = require("ffi")
local gl  = require("ffi/OpenGLES2")
local render_state = require("render_state_gles")
local shader_helper = require("lib.shader_helper")
--local xforms = require("transforms_gles")

-- Imports --
local Float3 = ffi.typeof("float[3]")
local Float4 = ffi.typeof("float[4]")

-- Exports --
local M = {}

-- --
local MVP = render_state.NewLazyMatrix()

-- --
local Pos = ffi.new("float[?][3]", 32)

-- --
local PrevPos = Float3() -- In case we want an "append"...

-- --
local Color = ffi.new("float[?][4]", 32)

-- --
local PrevColor = Float4()

-- --
local N = 0

-- --
local DrawBatch

--
local LocMVP
local LocPos, LocColor

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
			sp:BindUniformMatrix(LocMVP, MVP.matrix[0])
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
		sp:BindAttributeStream(LocPos, Pos, 3)
		sp:BindAttributeStream(LocColor, Color, 4)
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

LocMVP = SP:GetUniformByName("mvp")

LocPos = SP:GetAttributeByName("position")
LocColor = SP:GetAttributeByName("color")

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

	local out = def

	if ffi.istype(Float3, color) or type(color) == "table" then
		out = Float4(1, 1, 1, 1)

		if ffi.istype(Float3, color) then
			ffi.copy(out, color, ffi.sizeof(Float3))
		else
			assert(#color == 3 or #color == 4, "Invalid color array")

			for i = 1, #color do
				out[i - 1] = color[i]
			end
		end
	elseif def == nil then
		out = Float4(1, 1, 1, 1)
	end

	return out
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