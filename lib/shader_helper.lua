--- A wrapper around common shader operations.

--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
--

-- Standard library imports --
local assert = assert
local ipairs = ipairs
local setmetatable = setmetatable

-- Modules --
local ffi = require("ffi")
local gl = require("ffi/OpenGLES2")
local shaders = require("shaders_gles")

-- Exports --
local M = {}

--
local ShaderMT = {}

ShaderMT.__index = ShaderMT

--- DOCME
function ShaderMT:BindAttributeStream (name, stream, size)
	local loc = assert(self._anames[name], "Invalid attribute name")

	gl.glVertexAttribPointer(loc, size, gl.GL_FLOAT, gl.GL_FALSE, 0, stream)
end

--- DOCME
function ShaderMT:BindAttributeStreamByLoc (loc, stream, size)
	gl.glVertexAttribPointer(loc, size, gl.GL_FLOAT, gl.GL_FALSE, 0, stream)
end

--- DOCME
function ShaderMT:BindUniformMatrix (name, matrix)
	local loc = assert(self._unames[name], "Invalid uniform name")

	gl.glUniformMatrix4fv(loc, 1, gl.GL_FALSE, matrix)
end

--- DOCME
function ShaderMT:BindUniformMatrixByLoc (loc, matrix)
	gl.glUniformMatrix4fv(loc, 1, gl.GL_FALSE, matrix)
end

-- --
local BoundLocs

--
local function Disable ()
	for i = 1, #(BoundLocs or "") do
		gl.glDisableVertexAttribArray(BoundLocs[i])
	end

	BoundLocs = nil
end

--- DOCME
function ShaderMT:Disable ()
	if self._alocs == BoundLocs then
		Disable()
	end
end

--
local function Enable (shader)
	if shader._alocs ~= BoundLocs then
		Disable()

		for _, aloc in ipairs(shader._alocs) do
			gl.glEnableVertexAttribArray(aloc)
		end

		BoundLocs = shader._alocs
	end
end

--- DOCME
function ShaderMT:DrawArrays (type, count, base)
	Enable(self)

	gl.glDrawArrays(type, base or 0, count)
end

--- DOCME
function ShaderMT:DrawElements (type, indices, num_indices)
	Enable(self)

	gl.glDrawElements(type, num_indices, gl.GL_UNSIGNED_SHORT, indices)
end

--- DOCME
function ShaderMT:GetAttributeByName (name)
	return self._anames[name]
end

--- DOCME
function ShaderMT:GetUniformByName (name)
	return self._unames[name]
end

--- DOCME
function ShaderMT:Use ()
	gl.glUseProgram(self._program)
end

--
local function EnumFeatures (str, prog, patt, func)
	local locs, names = {}, {}

	for prec, ftype, name in str:gmatch(patt) do
		local loc = gl[func](prog, name)

		locs[#locs + 1], names[name] = loc, loc
	end

	return locs, names
end

--- DOCME
-- @string vs_source
-- @string fs_source
-- @treturn table X
-- @treturn string Y
function M.NewShader (vs_source, fs_source)
	local prog, err = shaders.LoadProgram(vs_source, fs_source)

	if prog ~= 0 then
		-- TODO: Figure out pattern to consume GLSL comments...
		-- ("//.*\n") ????
		-- ("/*.**/") ????

		-- Enumerate attributes and uniforms.
		local alocs, anames = EnumFeatures(vs_source, prog, "attribute%s+(%a+)%s+(%w+)%s+(%w+)%s*;", "glGetAttribLocation")
		local ulocs, unames = EnumFeatures(vs_source, prog, "uniform%s+(%a+)%s+(%w+)%s+(%w+)%s*;", "glGetUniformLocation")

		-- Varyings, too?

		return setmetatable({ _alocs = alocs, _anames = anames, _ulocs = ulocs, _unames = unames, _program = prog }, ShaderMT)
	else
		return nil, err
	end
end

-- Export the module.
return M