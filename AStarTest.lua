package.path = "./?.lua;./lib/?.lua"

-- Modules --
local bit = require("bit")
local ffi = require("ffi")
local gl = require("ffi/OpenGL")
local numeric_ops = require("numeric_ops")
local sdl = require("ffi/SDL")
local tw = require("ffi/AntTweakBar")

-- Imports --
local CellToIndex = numeric_ops.CellToIndex
local IndexToCell = numeric_ops.IndexToCell

--
local _M = {}

--
local Option = ({
	FH = "AStarFibonacciHeap",
	PH = "AStarPairingHeap",
	FS = "AStarFringeSearch"
})[string.upper(... or "FH")]

if Option then
	Option = require(Option)
else
	print("Invalid option " .. (...))
	return
end

-- --
local SW, SH = 780, 640

--
sdl.SDL_GL_SetAttribute(sdl.SDL_GL_RED_SIZE, 8)
sdl.SDL_GL_SetAttribute(sdl.SDL_GL_GREEN_SIZE, 8)
sdl.SDL_GL_SetAttribute(sdl.SDL_GL_BLUE_SIZE, 8)
sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 16)
sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1)
sdl.SDL_SetVideoMode(SW, SH, 32, bit.bor(sdl.SDL_OPENGL, sdl.SDL_HWSURFACE))

--
sdl.SDL_WM_SetCaption("Pathfinding tests", "TESTING")
sdl.SDL_EnableUNICODE(1)
sdl.SDL_EnableKeyRepeat(sdl.SDL_DEFAULT_REPEAT_DELAY, sdl.SDL_DEFAULT_REPEAT_INTERVAL)

--
gl.glViewport(0, 0, SW, SH)
gl.glEnable(gl.GL_DEPTH_TEST)
gl.glEnable(gl.GL_LIGHTING)
gl.glEnable(gl.GL_LIGHT0)
gl.glEnable(gl.GL_NORMALIZE)
gl.glEnable(gl.GL_COLOR_MATERIAL)
gl.glDisable(gl.GL_CULL_FACE)
gl.glColorMaterial(gl.GL_FRONT_AND_BACK, gl.GL_DIFFUSE)

--
tw.TwInit( tw.TW_OPENGL, nil )
local bar      = tw.TwNewBar( "Blah" )
local var1data = ffi.new( "double[1]" )
local var1     = tw.TwAddVarRW( bar, "Var1", tw.TW_TYPE_DOUBLE, var1data, "min = 0, max = .99, step = .01")
local var2data = ffi.new( "int32_t[1]" )
local var2     = tw.TwAddVarRO( bar, "Var2", tw.TW_TYPE_INT32, var2data, nil)

--
ffi.cdef [[
	typedef struct {
		uint8_t r, g, b, a;
	} Color_t;
]]

local ColorCT = ffi.typeof("Color_t")

--
local function DrawRect (x, y, w, h, color)
	local sx, sy = x, y
	local ex, ey = x + w, y + h

	gl.glColor3ub(color.r, color.g, color.b)

	gl.glBegin(gl.GL_QUADS)
		gl.glVertex2f(sx, sy)
		gl.glVertex2f(ex, sy)
		gl.glVertex2f(ex, ey)
		gl.glVertex2f(sx, ey)
	gl.glEnd()
end

-- --
local MouseX, MouseY = 0, 0

-- --
local MouseDown = false

-- --
local NC, NR = 35, 35

--
local function XToColumn ()
	local mx = MouseX - 35

	if mx >= 0 then
		local col, rem = math.floor(mx / 17) + 1, mx % 17

		if col <= NC and rem < 15 then
			return col
		end
	end
end

--
local function YToRow ()
	local my = MouseY - 20

	if my >= 0 then
		local row, rem = math.floor(my / 17) + 1, my % 17

		if row <= NR and rem < 15 then
			return row
		end
	end
end

-- --
local State

-- --
local Zone

-- --
local SCell, GCell

--
local function SetupZone ()
	if not Zone then
		SCell = 1
		GCell = NC * NR

		State = {}

		Zone = Option.GenerateZone(NC, NR)
	end
end

-- --
local Mode = 1

-- --
local ModeList = { "obstacle", "start", "goal", "clear" }

--
local function MarkCell ()
	local col, row = XToColumn(), YToRow()

	if col and row then
		SetupZone()

		local mode = ModeList[Mode]
		local cell = CellToIndex(col, row, NC)

		if mode == "start" and cell ~= GCell then
			SCell = cell
		elseif mode == "goal" and cell ~= SCell then
			GCell = cell
		elseif cell ~= SCell and cell ~= GCell then
			State[cell] = mode

			;(mode == "obstacle" and Option.SetCell or Option.ClearCell)(Zone, col, row)
		end
	end
end

-- --
local ModeColors = {
	start = ColorCT(0x00, 0xFF, 0x00, 0xFF),
	goal = ColorCT(0xFF, 0x00, 0x00, 0xFF),
	obstacle = ColorCT(0x00, 0x00, 0xFF, 0xFF),
	path = ColorCT(0x00, 0xFF, 0x00, 0xFF),
	open = ColorCT(0xFF, 0xFF, 0xFF, 0xFF),
	closed = ColorCT(0xFF, 0xFF, 0x00, 0xFF)
}

-- --
local Gray = ColorCT(0x1F, 0x1F, 0x1F, 0xFF)

--
local function GetColor (name)
	return ModeColors[name] or Gray
end

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
			handled = tw.TwKeyPressed(bit.band(sym, 0xFF), event.key.keysym.mod);

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
		tw.TwWindowSize(event.resize.w, event.resize.h);
	end

	return handled ~= 0
end

--
local function Render ()
	--
	gl.glClearColor(0, 0, 0, 1)
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	--
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glLoadIdentity()
	gl.glTranslated(-1, 1, 0)
	gl.glScaled(2 / SW, -2 / SH, 1)

	--
	DrawRect(720, 25, 32, 32, GetColor(ModeList[Mode]))

	--
	local index = 1
	local y = 20

	for i = 1, NR do
		local x = 35

		for j = 1, NC do
			local what = State[index]

			if index == SCell then
				what = "start"
			elseif index == GCell then
				what = "goal"
			end

			DrawRect(x, y, 15, 15, GetColor(what))

			index = index + 1
			x = x + 17
		end

		y = y + 17
	end

	--
	sdl.SDL_Delay(10)
end

--[[
int main()
{
	const SDL_VideoInfo* video = NULL;
    int width  = 640, height = 480;
	int bpp, flags;
	int quit = 0;
	TwBar *bar;
	int n, numCubes = 30;
	float color0[] = { 1.0f, 0.5f, 0.0f };
	float color1[] = { 0.5f, 1.0f, 0.0f };
	double ka = 5.3, kb = 1.7, kc = 4.1;

	// Initialize SDL, then get the current video mode and use it to create a SDL window.
    if( SDL_Init(SDL_INIT_VIDEO)<0 )
	{
		fprintf(stderr, "Video initialization failed: %s\n", SDL_GetError());
		SDL_Quit();
        exit(1);
    }

	SDL_WM_SetCaption("AntTweakBar simple example using SDL", "AntTweakBar+SDL");
	// Enable SDL unicode and key-repeat
	SDL_EnableUNICODE(1);
	SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);

	// Set OpenGL viewport and states
	glViewport(0, 0, width, height);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);	// use default light diffuse and position
	glEnable(GL_NORMALIZE);
	glEnable(GL_COLOR_MATERIAL);
	glDisable(GL_CULL_FACE);
	glColorMaterial(GL_FRONT_AND_BACK, GL_DIFFUSE);

	// Initialize AntTweakBar
	TwInit(TW_OPENGL, NULL);
	// Tell the window size to AntTweakBar
	TwWindowSize(width, height);

	// Create a tweak bar
	bar = TwNewBar("TweakBar");

	// Add 'width' and 'height' to 'bar': they are read-only (RO) variables of type TW_TYPE_INT32.
	TwAddVarRO(bar, "Width", TW_TYPE_INT32, &width, " label='Wnd width (pixels)' ");
	TwAddVarRO(bar, "Height", TW_TYPE_INT32, &height, " label='Wnd height (pixels)' ");
	// Add 'quit' to 'bar': it is a modifiable (RW) variable of type TW_TYPE_BOOL32 (boolean stored in a 32 bits integer). Its shortcut is [ESC].
	TwAddVarRW(bar, "Quit", TW_TYPE_BOOL32, &quit, " label='Quit?' true='+' false='-' key='ESC' ");
	// Add 'numCurves' to 'bar': it is a modifiable variable of type TW_TYPE_INT32. Its shortcuts are [c] and [C].
	TwAddVarRW(bar, "NumCubes", TW_TYPE_INT32, &numCubes, " label='Number of cubes' min=1 max=100 keyIncr=c keyDecr=C ");
	// Add 'ka', 'kb and 'kc' to 'bar': they are modifiable variables of type TW_TYPE_DOUBLE
	TwAddVarRW(bar, "ka", TW_TYPE_DOUBLE, &ka, " label='X path coeff' keyIncr=1 keyDecr=CTRL+1 min=-10 max=10 step=0.01 ");
	TwAddVarRW(bar, "kb", TW_TYPE_DOUBLE, &kb, " label='Y path coeff' keyIncr=2 keyDecr=CTRL+2 min=-10 max=10 step=0.01 ");
	TwAddVarRW(bar, "kc", TW_TYPE_DOUBLE, &kc, " label='Z path coeff' keyIncr=3 keyDecr=CTRL+3 min=-10 max=10 step=0.01 ");
	// Add 'color0' and 'color1' to 'bar': they are modifable variables of type TW_TYPE_COLOR3F (3 floats color)
	TwAddVarRW(bar, "color0", TW_TYPE_COLOR3F, &color0, " label='Start color' ");
	TwAddVarRW(bar, "color1", TW_TYPE_COLOR3F, &color1, " label='End color' ");

	// Main loop:
	// - Draw some cubes
	// - Process events
    while( !quit )
	{
		SDL_Event event;
		int handled;

		// Clear screen
		glClearColor(0.6f, 0.95f, 1.0f, 1);
		glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

		// Set OpenGL camera
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		gluPerspective(40, (double)width/height, 1, 10);
		gluLookAt(0,0,3, 0,0,0, 0,1,0);

		// Draw cubes
		for( n=0; n<numCubes; ++n )
		{
			double t = 0.05*n - (double)SDL_GetTicks()/2000.0;
			double r = 5.0*n + (double)SDL_GetTicks()/10.0;
			float c = (float)n/numCubes;

			// Set cube position
			glMatrixMode(GL_MODELVIEW);
			glLoadIdentity();
			glTranslated(0.4+0.6*cos(ka*t), 0.6*cos(kb*t), 0.6*sin(kc*t));
			glRotated(r, 0.2, 0.7, 0.2);
			glScaled(0.1, 0.1, 0.1);
			glTranslated(-0.5, -0.5, -0.5);

			// Set cube color
			glColor3f((1.0f-c)*color0[0]+c*color1[0], (1.0f-c)*color0[1]+c*color1[1], (1.0f-c)*color0[2]+c*color1[2]);

			// Draw cube
			glBegin(GL_QUADS);
				glNormal3f(0,0,-1); glVertex3f(0,0,0); glVertex3f(0,1,0); glVertex3f(1,1,0); glVertex3f(1,0,0);	// front face
				glNormal3f(0,0,+1); glVertex3f(0,0,1); glVertex3f(1,0,1); glVertex3f(1,1,1); glVertex3f(0,1,1);	// back face
				glNormal3f(-1,0,0); glVertex3f(0,0,0); glVertex3f(0,0,1); glVertex3f(0,1,1); glVertex3f(0,1,0);	// left face
				glNormal3f(+1,0,0); glVertex3f(1,0,0); glVertex3f(1,1,0); glVertex3f(1,1,1); glVertex3f(1,0,1); // right face
				glNormal3f(0,-1,0); glVertex3f(0,0,0); glVertex3f(1,0,0); glVertex3f(1,0,1); glVertex3f(0,0,1);	// bottom face	
				glNormal3f(0,+1,0); glVertex3f(0,1,0); glVertex3f(0,1,1); glVertex3f(1,1,1); glVertex3f(1,1,0);	// top face
			glEnd();
		}

		// Draw tweak bars
		TwDraw();

		// Present frame buffer
		SDL_GL_SwapBuffers();

        // Process incoming events
		while( SDL_PollEvent(&event) ) 
		{
			// Send event to AntTweakBar
			handled = TwEventSDL(&event);

			// If event has not been handled by AntTweakBar, process it
			if( !handled )
			{
				switch( event.type )
				{
				case SDL_QUIT:	// Window is closed
					quit = 1;
					break;
				case SDL_VIDEORESIZE:	// Window size has changed
					// Resize SDL video mode
 					width = event.resize.w;
					height = event.resize.h;
					if( !SDL_SetVideoMode(width, height, bpp, flags) )
						fprintf(stderr, "WARNING: Video mode set failed: %s", SDL_GetError());
					// Resize OpenGL viewport
					glViewport(0, 0, width, height);
					// Restore OpenGL states (SDL seems to lost them)
					glEnable(GL_DEPTH_TEST);
					glEnable(GL_LIGHTING);
					glEnable(GL_LIGHT0);
					glEnable(GL_NORMALIZE);
					glEnable(GL_COLOR_MATERIAL);
					glDisable(GL_CULL_FACE);
					glColorMaterial(GL_FRONT_AND_BACK, GL_DIFFUSE);
					// TwWindowSize has been called by TwEventSDL, so it is not necessary to call it again here.
					break;
				}
			}
		}
    } // End of main loop

	// Terminate AntTweakBar
	TwTerminate();

	// Terminate SDL
	SDL_Quit();

	return 0;
}  
]]



--[[
local function main()
   local desktop_width  = 0
   local desktop_height = 0
   local width          = 640
   local height         = 480

   tw.TwInit( tw.TW_OPENGL, nil )
   local bar      = tw.TwNewBar( "Blah" )
   local var1data = ffi.new( "double[1]" )
   local var1     = tw.TwAddVarRW( bar, "Var1", tw.TW_TYPE_DOUBLE, var1data, nil)
   local var2data = ffi.new( "int32_t[1]" )
   local var2     = tw.TwAddVarRO( bar, "Var2", tw.TW_TYPE_INT32, var2data, nil)

   local mouse = { 
      x = 0, y = 0, wheel = 0,
      buttons = { {}, {}, {} },
   }
   
   local int1, int2 = ffi.new( "int[1]" ), ffi.new( "int[1]" )
   while glfw.glfwIsWindow(window) 
   and   glfw.glfwGetKey(window, glfw.GLFW_KEY_ESCAPE) ~= glfw.GLFW_PRESS 
   do
      glfw.glfwGetWindowSize(window, int1, int2)
      width, height = int1[0], int2[0]
      
      gl.glClear(gl.GL_COLOR_BUFFER_BIT)
      gl.glMatrixMode(gl.GL_PROJECTION)
      gl.glLoadIdentity()
      gl.glMatrixMode( gl.GL_MODELVIEW )
      gl.glLoadIdentity()
 
      glfw.glfwGetMousePos(window, int1, int2)
      mouse.x, mouse.y = int1[0], int2[0]

      do -- AntTweakBar
	 for i=1, #mouse.buttons do
	    local should_signal = nil
	    local b = mouse.buttons[i]
	    b.repeat_after = b.repeat_after or 0.25
	    b.new_state = glfw.glfwGetMouseButton( window, glfw.GLFW_MOUSE_BUTTON_LEFT + i - 1 )
	    if b.old_state ~= b.new_state then
	       b.old_state = b.new_state
	       b.last_time = os.clock()
	       should_signal = true
	    elseif b.new_state == glfw.GLFW_PRESS then
	       should_signal = (os.clock() - b.last_time > b.repeat_after)
	    end
	    if should_signal then
	       tw.TwMouseButton( b.new_state, tw.TW_MOUSE_LEFT + i - 1 )
	    end
	 end
	 glfw.glfwGetScrollOffset( window, int1, int2 )
	 mouse.wheel = mouse.wheel + int2[0]
	 var2data[0] = mouse.wheel
	 tw.TwMouseWheel(mouse.wheel)
	 tw.TwMouseMotion(mouse.x, mouse.y)
	 tw.TwWindowSize(width, height)
	 tw.TwDraw()
      end

      glfw.glfwSwapBuffers()
      glfw.glfwPollEvents()
   end

   glfw.glfwTerminate()
end

main()
]]

--
SetupZone()

-- --
local Event = ffi.new("SDL_Event")

--
local ShouldExit

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
					Mode = numeric_ops.RotateIndex(Mode, #ModeList)

				elseif key == sdl.SDLK_RETURN then
					SetupZone()

					local scol, srow = IndexToCell(SCell, NC)
					local ecol, erow = IndexToCell(GCell, NC)

					local t1 = os.clock()

					local p, pp = Option.GeneratePath(Zone, scol, srow, ecol, erow)

					local t2 = os.clock()

					Zone = nil

					if p then
						print(string.format("Path length: %i, time = %f", p.n, t2 - t1))
					else
						print(string.format("FAIL!, time = %f", t2 - t1))
					end

					for index = 1, NC * NR do
						if Option.IsOpen(pp, index - 1) then
							State[index] = "open"
						elseif Option.IsClosed(pp, index - 1) then
							State[index] = "closed"
						end
					end

					if p then
						for i = 0, p.n - 1 do
							local index = CellToIndex(p.cells[i].col, p.cells[i].row, NC)

							State[index] = "path"
						end
					end
				end

			elseif etype == sdl.SDL_MOUSEMOTION then
				MouseX, MouseY = motion.x, motion.y

				if MouseDown then
					MarkCell()
				end

			elseif etype == sdl.SDL_MOUSEBUTTONDOWN and button == 1 then
				if not handled then
					MouseDown = true

					MarkCell()
				end

			elseif etype == sdl.SDL_MOUSEBUTTONUP and button == 1 then
				MouseDown = false
			end
		end
	end

	Render()

	tw.TwWindowSize(SW, SH)
	tw.TwDraw()

	sdl.SDL_GL_SwapBuffers()
end

sdl.SDL_Quit()

return _M