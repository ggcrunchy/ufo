-- Modules --
local bit = require("bit")
local ffi = require("ffi")
local gl = require("ffi/OpenGL")
local sdl = require("ffi/SDL")
local tw = require("ffi/AntTweakBar")

-- --
local SW, SH = 1600, 900

--
sdl.SDL_GL_SetAttribute(sdl.SDL_GL_RED_SIZE, 8)
sdl.SDL_GL_SetAttribute(sdl.SDL_GL_GREEN_SIZE, 8)
sdl.SDL_GL_SetAttribute(sdl.SDL_GL_BLUE_SIZE, 8)
sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 16)
sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1)
sdl.SDL_SetVideoMode(SW, SH, 32, bit.bor(sdl.SDL_OPENGL, sdl.SDL_HWSURFACE))

--
sdl.SDL_WM_SetCaption("Lightning test", "TESTING")
sdl.SDL_EnableUNICODE(1)
sdl.SDL_EnableKeyRepeat(sdl.SDL_DEFAULT_REPEAT_DELAY, sdl.SDL_DEFAULT_REPEAT_INTERVAL)

--
gl.glViewport(0, 0, SW, SH)
gl.glEnable(gl.GL_BLEND)
gl.glEnable(gl.GL_DEPTH_TEST)
gl.glEnable(gl.GL_LIGHTING)
gl.glEnable(gl.GL_LIGHT0)
gl.glEnable(gl.GL_NORMALIZE)
gl.glEnable(gl.GL_COLOR_MATERIAL)
gl.glDisable(gl.GL_CULL_FACE)
gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_DST_ALPHA)
gl.glColorMaterial(gl.GL_FRONT_AND_BACK, gl.GL_DIFFUSE)

--
local Texture = ffi.new("GLuint[1]")

local Image = ffi.new("GLubyte[64][64][4]")

for i = 0, 63 do
	for j = 0, 63 do
		local diff, a = math.abs(i - 31.5), 255

		if diff >= 15 then
			local c = 1 - ((diff - 15) / 16.5)^2

			a = math.floor(0x1F + 0x35 * c)
		end

		Image[i][j][0] = a--255
        Image[i][j][1] = a--255
        Image[i][j][2] = a--255
        Image[i][j][3] = a
	end
end

gl.glPixelStorei(gl.GL_UNPACK_ALIGNMENT, 1)
gl.glGenTextures(1, Texture)
gl.glBindTexture(gl.GL_TEXTURE_2D, Texture[0])

gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_REPEAT)
gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_REPEAT)
gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST)
gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST)
gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, 64, 64, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, Image)

--
tw.TwInit( tw.TW_OPENGL, nil )

local bar      = tw.TwNewBar( "Blah" )

local vCOLOR = ffi.new( "float[3]", 0, 0, 1 )
local var1     = tw.TwAddVarRW( bar, "Color", tw.TW_TYPE_COLOR3F, vCOLOR, nil)

local vANGLE = ffi.new( "double[1]", 16 )
local var2     = tw.TwAddVarRW( bar, "Angle", tw.TW_TYPE_DOUBLE, vANGLE, "min = 5, max = 90, step = .1")

local vWIDTH = ffi.new( "double[1]", 2.1 )
local var3     = tw.TwAddVarRW( bar, "Width", tw.TW_TYPE_DOUBLE, vWIDTH, "min = 1, max = 10, step = .1")

local vPERIOD = ffi.new( "double[1]", .15 )
local var4     = tw.TwAddVarRW( bar, "Period", tw.TW_TYPE_DOUBLE, vPERIOD, "min = .05, max = 1.5, step = .01")

local vSCALE = ffi.new( "double[1]", .7 )
local var5     = tw.TwAddVarRW( bar, "Scale", tw.TW_TYPE_DOUBLE, vSCALE, "min = .1, max = .95, step = .05")

local vFORK = ffi.new( "double[1]", .4 )
local var6     = tw.TwAddVarRW( bar, "Fork", tw.TW_TYPE_DOUBLE, vFORK, "min = .05, max = .95, step = .05")

local vJITTER = ffi.new( "double[1]", .5 )
local var7     = tw.TwAddVarRW( bar, "Jitter", tw.TW_TYPE_DOUBLE, vJITTER, "min = .05, max = 2.5, step = .025")

local vOFFSET = ffi.new( "uint32_t[1]", 90 )
local var8     = tw.TwAddVarRW( bar, "Offset", tw.TW_TYPE_UINT32, vOFFSET, "min = 25, max = 250, step = 1")

local vGENS = ffi.new( "uint32_t[1]", 5 )
local var9     = tw.TwAddVarRW( bar, "Generations", tw.TW_TYPE_UINT32, vGENS, "min = 1, max = 10, step = 1")

local vLAYERS = ffi.new( "double[1]", .4 )
local varA     = tw.TwAddVarRW( bar, "Layers", tw.TW_TYPE_DOUBLE, vLAYERS, "min = .1, max = 2, step = .05")

--- @brief      Helper: 
---             translate and re-send mouse and keyboard events 
---             from SDL 1.3 event loop to AntTweakBar
--- 
--- @author     Philippe Decaudin - http://www.antisphere.com
--- @license    This file is part of the AntTweakBar library.
---             For conditions of distribution and use, see License.txt
local s_KeyMod = 0
local s_WheelPos = 0

local Keys = {
	[sdl.SDLK_UP] = tw.TW_KEY_UP,
	[sdl.SDLK_DOWN] = tw.TW_KEY_DOWN,
	[sdl.SDLK_RIGHT] = tw.TW_KEY_RIGHT,
	[sdl.SDLK_LEFT] = tw.TW_KEY_LEFT,
	[sdl.SDLK_INSERT] = tw.TW_KEY_INSERT,
	[sdl.SDLK_HOME] = tw.TW_KEY_HOME,
	[sdl.SDLK_END] = tw.TW_KEY_END,
	[sdl.SDLK_PAGEUP] = tw.TW_KEY_PAGE_UP,
	[sdl.SDLK_PAGEDOWN] = TW_KEY_PAGE_DOWN
}

local function TwEvent (event)
	--  The way SDL handles keyboard events has changed between version 1.2
	--  and 1.3. It is now more difficult to translate SDL keyboard events to 
	--  AntTweakBar events. The following code is an attempt to do so, but
	--  it is rather complex and not always accurate (eg, CTRL+1 is not handled).
	--  If someone knows a better and more robust way to do the keyboard events
	--  translation, please let me know.
	local handled = 0
	local etype = event.type

	-- Text input --
	if etype == sdl.SDL_TEXTINPUT then
		if event.text.text[0] ~= 0 and event.text.text[1] == 0 then
			if bit.band(s_KeyMod, tw.TW_KMOD_CTRL) ~= 0 and event.text.text[0] < 32 then
				handled = tw.TwKeyPressed(event.text.text[0] + string.byte("a") - 1, s_KeyMod)
			else
				if bit.band(s_KeyMod, sdl.KMOD_RALT) then
					s_KeyMod = bit.band(s_KeyMod, bit.bnot(sdl.KMOD_CTRL))
				end

				handled = tw.TwKeyPressed(event.text.text[0], s_KeyMod)
			end
		end

		s_KeyMod = 0

	-- Key down --
	elseif etype == sdl.SDL_KEYDOWN then
		local sym = event.key.keysym.sym

		if bit.band(sym, bit.lshift(1, 30)) ~= 0 then -- 1 << 30 == SDLK_SCANCODE_MASK
			local key = Keys[sym]

			if not key and sym >= sdl.SDLK_F1 and sym <= sdl.SDLK_F12 then
				key = sym + tw.TW_KEY_F1 - sdl.SDLK_F1
			end

			if key then
				handled = tw.TwKeyPressed(key, event.key.keysym.mod)
			end

		elseif bit.band(event.key.keysym.mod, tw.TW_KMOD_ALT) ~= 0 then
			handled = tw.TwKeyPressed(bit.band(sym, 0xFF), event.key.keysym.mod)

		else
			s_KeyMod = event.key.keysym.mod
		end

	-- Key up --
	elseif etype == sdl.SDL_KEYUP then
		s_KeyMod = 0

	-- Mouse motion --
	elseif etype == sdl.SDL_MOUSEMOTION then
		handled = tw.TwMouseMotion(event.motion.x, event.motion.y)

	-- Mouse button --
	elseif etype == sdl.SDL_MOUSEBUTTONUP or etype == sdl.SDL_MOUSEBUTTONDOWN then
		if etype == sdl.SDL_MOUSEBUTTONDOWN and (event.button.button == 4 or event.button.button == 5) then  -- mouse wheel
			if event.button.button == 4 then
				s_WheelPos = s_WheelPos + 1
			else
				s_WheelPos = s_WheelPos - 1
			end

			handled = tw.TwMouseWheel(s_WheelPos)

		else
			handled = tw.TwMouseButton(etype == sdl.SDL_MOUSEBUTTONUP and tw.TW_MOUSE_RELEASED or tw.TW_MOUSE_PRESSED, event.button.button)
		end

	-- Video resize --
	elseif etype == sdl.SDL_VIDEORESIZE then
		tw.TwWindowSize(event.resize.w, event.resize.h)
	end

	return handled ~= 0
end

local S2 = {}

local SX, SY, EX, EY = SW * .15, SH / 2, SW * .85, SH / 2

local function Dir (seg)
	local dx, dy = seg.p2.x - seg.p1.x, seg.p2.y - seg.p1.y
	local len = math.sqrt(dx * dx + dy * dy)

	return dx / len, dy / len
end

local function Normal (dx, dy, scale)
	if scale then
		local len = math.sqrt(dx * dx + dy * dy)

		dx, dy = dx / len, dy / len
	end

	return { x = -dy, y = dx }
end

local function Rand (n)
	return -n + 2 * math.random() * n
end

local function ComputeSegments ()
	local offset = vOFFSET[0]

	local first = { p1 = { x = SX, y = SY }, p2 = { x = EX, y = EY } }
	local n = Normal(Dir(first))

	first.n1, first.n2 = n, n

	local segments = { first }

	for i = 1, vGENS[0] do
		for j, seg in ipairs(segments) do
			local dx, dy = Dir(seg)
			local mx, my = (seg.p1.x + seg.p2.x) / 2, (seg.p1.y + seg.p2.y) / 2
			local f = Rand(offset)

			mx = mx - dy * f
			my = my + dx * f

			local m = { x = mx, y = my }

			local seg1 = { p1 = seg.p1, p2 = m, n1 = seg.n1 }
			local seg2 = { p1 = m, p2 = seg.p2, n2 = seg.n2 }

			local dx1, dy1 = Dir(seg1)
			local dx2, dy2 = Dir(seg2)

			local n = Normal(dx1 + dx2, dy1 + dy2, true)

			seg1.n2 = n
			seg2.n1 = n

			S2[#S2 + 1] = seg1
			S2[#S2 + 1] = seg2

			if not seg.split and math.random() < vFORK[0] then
				local angle = math.rad(Rand(vANGLE[0]))
				local ca, sa = math.cos(angle), math.sin(angle)

				dx, dy = (seg.p2.x - mx) * vSCALE[0], (seg.p2.y - my) * vSCALE[0]

				S2[#S2 + 1] = { p1 = m, p2 = { x = mx + ca * dx - sa * dy, y = my + ca * dy + sa * dx }, n1 = n, n2 = Normal(dx, dy, true) }
			end

			segments[j] = nil
		end

		segments, S2, offset = S2, segments, offset / 2
	end

	return segments
end

--
local function JC (x, y, u, v)
	gl.glTexCoord2f(u, v)
	gl.glVertex2f(x + Rand(vJITTER[0]), y + Rand(vJITTER[0]))
end

--
local function Rect (p1, p2, n1, n2, a)
	gl.glColor4f(vCOLOR[0], vCOLOR[1], vCOLOR[2], a)

	local n1x, n1y = n1.x * vWIDTH[0], n1.y * vWIDTH[0]
	local n2x, n2y = n2.x * vWIDTH[0], n2.y * vWIDTH[0]

	JC(p1.x + n1x, p1.y + n1y, 0, 0)
	JC(p2.x + n2x, p2.y + n2y, 1, 0)
	JC(p2.x - n2x, p2.y - n2y, 1, 1)
	JC(p1.x - n1x, p1.y - n1y, 0, 1)
end

-- --
local Segments = ComputeSegments()

local T = 0

local GT = { 0, -vLAYERS[0] / 2 }--.2 }

--
local function Render (t)
	--
	gl.glClearColor(0, 0, 0, 1)
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	--
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glLoadIdentity()
	gl.glTranslated(-1, 1, 0)
	gl.glScaled(2 / SW, -2 / SH, 1)

	gl.glEnable(gl.GL_TEXTURE_2D)
	gl.glDisable(gl.GL_DEPTH_TEST)
	gl.glTexEnvf(gl.GL_TEXTURE_ENV, gl.GL_TEXTURE_ENV_MODE, gl.GL_MODULATE)
	gl.glBindTexture(gl.GL_TEXTURE_2D, Texture[0])

	gl.glBegin(gl.GL_QUADS)
		for i, seg in ipairs(Segments) do
			for _, t in ipairs(GT) do--vLAYERS[0] do
				if t >= 0 then
					local a = 1 - t / vLAYERS[0]--.4

					Rect(seg.p1, seg.p2, seg.n1, seg.n2, a)
				end
			end
		end
	gl.glEnd()
	gl.glDisable(gl.GL_TEXTURE_2D)
	gl.glEnable(gl.GL_DEPTH_TEST)

	--
	T = T + t

	if T > vPERIOD[0] then
		T = 0

		Segments = ComputeSegments()

		GT[1] = 0
		GT[2] = -vLAYERS[0] / 2

	--
	else
		for i = 1, 2 do
			GT[i] = GT[i] + t

			if GT[i] > vLAYERS[0] then
				GT[i] = GT[i] % vLAYERS[0]--.4
			end
		end
	end

	--
	sdl.SDL_Delay(10)
end

-- --
local Event = ffi.new("SDL_Event")

local Ticks = sdl.SDL_GetTicks()

--
local Down, ShouldExit = {}

local function UpdatePos (motion)
	if Down[1] then
		SX, SY = motion.x, motion.y
	end

	if Down[3] then
		EX, EY = motion.x, motion.y
	end
end

while not ShouldExit do
	while sdl.SDL_PollEvent(Event) ~= 0 do
		local etype, key = Event.type, Event.key.keysym.sym
		local handled = TwEvent(Event)

		if etype == sdl.SDL_QUIT or (etype == sdl.SDL_KEYUP and key == sdl.SDLK_ESCAPE) then
			ShouldExit = true

		else
			local motion, button = Event.motion, Event.button.button

			if etype == sdl.SDL_KEYUP then
				if key == sdl.SDLK_SPACE then

				elseif key == sdl.SDLK_RETURN then

				end

			elseif etype == sdl.SDL_MOUSEMOTION then
				UpdatePos(motion)

			elseif etype == sdl.SDL_MOUSEBUTTONDOWN then
				if not handled then
					Down[button] = true

					UpdatePos(motion)
				end

			elseif etype == sdl.SDL_MOUSEBUTTONUP then
				Down[button] = false
			end
		end
	end

	local ticks = sdl.SDL_GetTicks()

	Render((ticks - Ticks) / 1000)

	Ticks = ticks

	tw.TwWindowSize(SW, SH)
	tw.TwDraw()

	sdl.SDL_GL_SwapBuffers()
end

gl.glDeleteTextures(1, Texture)
sdl.SDL_Quit()