local ffi = require("ffi")
local bit = require("bit")
local egl = require( "ffi/EGL" )
local gl  = require( "ffi/OpenGLES2" )
local sdl = require( "ffi/sdl" )
   
local ww, wh = 512, 512

local KeyHandler
local MouseActionHandler
local MouseMotionHandler
local MouseWheelHandler

local Diff

-- Use SDL for windowing and events
local function InitSDL()
   local screen = sdl.SDL_SetVideoMode( ww, wh, 32, 0 * sdl.SDL_RESIZABLE )
   local wminfo = ffi.new( "SDL_SysWMinfo" )
   sdl.SDL_GetVersion( wminfo.version )
   sdl.SDL_GetWMInfo( wminfo )
   local systems = { "win", "x11", "dfb", "cocoa", "uikit" }
   local subsystem = tonumber(wminfo.subsystem)
   local wminfo = wminfo.info[systems[subsystem]]
   local window = wminfo.window
   local display = nil
   if systems[subsystem]=="x11" then
      display = wminfo.display
      print('X11', display, window)
   end			      
   local event = ffi.new( "SDL_Event" )
   local prev_time, curr_time, fps = 0, 0, 0
   return {
      window = window,
      display = display,
      update = function() 
               -- Calculate the frame rate
		  prev_time, curr_time = curr_time, os.clock()
		  local diff = curr_time - prev_time + 0.00001
		  local real_fps = 1/diff
		  if math.abs( fps - real_fps ) * 10 > real_fps then
		     fps = real_fps
		  end
		  fps = fps*0.99 + 0.01*real_fps
	 
      -- Update the window caption with statistics
--		  sdl.SDL_WM_SetCaption( string.format("%d %s %dx%d | %.2f fps | %.2f mps", ticks_base, tostring(bounce_mode), screen.w, screen.h, fps, fps * (screen.w * screen.h) / (1024*1024)), nil )
		  Diff = curr_time - prev_time
		  while sdl.SDL_PollEvent( event ) ~= 0 do
		     if event.type == sdl.SDL_QUIT then
			return false
		     end
		     if event.type == sdl.SDL_KEYUP and event.key.keysym.sym == sdl.SDLK_ESCAPE then
			event.type = sdl.SDL_QUIT
			sdl.SDL_PushEvent( event )
			 elseif event.type == sdl.SDL_KEYUP or event.type == sdl.SDL_KEYDOWN then
				KeyHandler(event.key, event.type == sdl.SDL_KEYDOWN)
			elseif event.type == sdl.SDL_MOUSEBUTTONDOWN or event.type == sdl.SDL_MOUSEBUTTONUP then
				MouseButtonHandler(event.button, event.type == sdl.SDL_MOUSEBUTTONDOWN)
			elseif event.type == sdl.SDL_MOUSEWHEEL then
				MouseWheelHandler(event.wheel)
			 elseif event.type == sdl.SDL_MOUSEMOTION then
				MouseMotionHandler(event.motion)
			 end
		  end
		  return true 
	       end,
      exit = function() 
		sdl.SDL_Quit() 
	     end,
   }
end

local wm = InitSDL()

print('DISPLAY',wm.display)
if wm.display == nil then
   wm.display = egl.EGL_DEFAULT_DISPLAY
end
local dpy      = egl.eglGetDisplay( ffi.cast("intptr_t", wm.display ))
local r        = egl.eglInitialize( dpy, nil, nil )

print('wm.display/dpy/r', wm.display, dpy, r)

local cfg_attr = ffi.new( "EGLint[3]", egl.EGL_RENDERABLE_TYPE, egl.EGL_OPENGL_ES2_BIT, egl.EGL_NONE )
local ctx_attr = ffi.new( "EGLint[3]", egl.EGL_CONTEXT_CLIENT_VERSION, 2, egl.EGL_NONE )

local cfg      = ffi.new( "EGLConfig[1]" )
local n_cfg    = ffi.new( "EGLint[1]"    )

print('wm.window', wm.window)

local r0       = egl.eglChooseConfig(        dpy, cfg_attr, cfg, 1, n_cfg )

local c = cfg[0]

for i=0,10 do
--    if c[i]==egl.EGL_FALSE then break end
--    print(i,c[i])
end

local surf     = egl.eglCreateWindowSurface( dpy, cfg[0], wm.window, nil )
local ctx      = egl.eglCreateContext(       dpy, cfg[0], nil, ctx_attr )
local r        = egl.eglMakeCurrent(         dpy,   surf, surf, ctx )

print('surf/ctx', surf, r0, ctx, r, n_cfg[0])

local function validate_shader( shader )
   local int = ffi.new( "GLint[1]" )
   gl.glGetShaderiv( shader, gl.GL_INFO_LOG_LENGTH, int )
   local length = int[0]
   if length <= 0 then
      return
   end
   gl.glGetShaderiv( shader, gl.GL_COMPILE_STATUS, int )
   local success = int[0]
   if success == gl.GL_TRUE then
      return
   end
   local buffer = ffi.new( "char[?]", length )
   gl.glGetShaderInfoLog( shader, length, int, buffer )
--   assert( int[0] == length )
   error( ffi.string(buffer) )
end
 
local function load_shader( src, type )
   local shader = gl.glCreateShader( type )
   if shader == 0 then
      error( "glGetError: " .. tonumber( gl.glGetError()) )
   end
   local src = ffi.new( "char[?]", #src, src )
   local srcs = ffi.new( "const char*[1]", src )
   gl.glShaderSource( shader, 1, srcs, nil )
   gl.glCompileShader ( shader )
   validate_shader( shader )
   return shader
end

-- COLLISION --

-- Ufff... broad sweep...
-- Sphere thing

-- WALKING THE SPACE --

-- Rays?
-- Octree...

-- PAINT BEAM --

-- Cylinder collision, then curve

-- VACUUM BEAM --

-- Cone collision, then curve?


-- TODO LIST --
--[[
1: Floor, walls, some stuff in middle generating and displaying
2: Ray collisions
3: Movement
4: Reticle
5: Paint
6: Vacuum
7: Tweakables
8: ???
]]

local textures = require("textures_gles")

local LOGO_FILE = "icon.bmp"

local cursor_texture = ffi.new("GLuint[1]")

local minx, miny, maxx, maxy, iw, ih

local function DrawLogoCursor (x, y)
	if cursor_texture[0] == 0 then
		local file = sdl.SDL_RWFromFile(LOGO_FILE, "rb")
		local image = sdl.SDL_LoadBMP_RW(file, 1)

		if image ~= nil then
			iw = image.w
			ih = image.h

			cursor_texture[0], minx, miny, maxx, maxy = textures.LoadTexture(image)

			sdl.SDL_FreeSurface(image)
		end

		if cursor_texture[0] == 0 then
			return
		end
	end

	textures.Begin2D()

	textures.Draw(cursor_texture[0], x, y, iw, ih, minx, miny, maxx, maxy)

	textures.End2D()
end

local color = ffi.new("GLfloat[960]", {
	1.0,  1.0,  0.0, 1.0,  -- 0
	1.0,  0.0,  0.0,  1.0, -- 1
	0.0,  1.0,  0.0, 1.0,  -- 3
	0.0,  0.0,  0.0,  1.0, -- 2

	0.0,  1.0,  0.0, 1.0,  -- 3
	0.0,  1.0,  1.0,  1.0, -- 4
	0.0,  0.0,  0.0, 1.0,  -- 2
	0.0,  0.0,  1.0, 1.0,  -- 7

	1.0,  1.0,  0.0, 1.0,  -- 0
	1.0,  1.0,  1.0, 1.0,  -- 5
	1.0,  0.0,  0.0, 1.0,  -- 1
	1.0,  0.0,  1.0, 1.0,  -- 6

	1.0,  1.0,  1.0, 1.0,  -- 5
	0.0,  1.0,  1.0, 1.0,  -- 4
	1.0,  0.0,  1.0, 1.0,  -- 6
	0.0,  0.0,  1.0, 1.0,  -- 7

	1.0,  1.0,  1.0, 1.0,  -- 5
	1.0,  1.0,  0.0, 1.0,  -- 0
	0.0,  1.0,  1.0, 1.0,  -- 4
	0.0,  1.0,  0.0, 1.0,  -- 3

	1.0,  0.0,  1.0, 1.0,  -- 6
	1.0,  0.0,  0.0, 1.0,  -- 1
	0.0,  0.0,  1.0, 1.0,  -- 7
	0.0,  0.0,  0.0, 1.0,  -- 2
})
for i = 1, 9 do
	for j = 0, 95 do
	color[i * 96 + j] = color[j]
	end
end

local shaders = require("shaders_gles")
local shapes = require("shapes_gles")
local xforms = require("transforms_gles")

local sp = shaders.LoadProgram(
	[[
		attribute lowp vec4 color;
		attribute mediump vec3 position;
		varying lowp vec3 col;
		uniform mediump mat4 mvp;

		void main ()
		{
			gl_Position = mvp * vec4(position, 1);

			col = color.rgb;
		}
	]],
	[[
		varying lowp vec3 col;

		void main ()
		{
			gl_FragColor = vec4(col, 1);
		}
	]]
)

local loc_color = gl.glGetAttribLocation(sp, "color")
local loc_position = gl.glGetAttribLocation(sp, "position")
local loc_mvp = gl.glGetUniformLocation(sp, "mvp")

local proj = xforms.New()

xforms.MatrixLoadIdentity(proj)
xforms.Perspective(proj, 70, ww / wh, 1, 1000)

local camera = xforms.New()

xforms.MatrixLoadIdentity(camera)

local mvp = xforms.New()

gl.glViewport( 0, 0, ww, wh )

local mc = require("mouse_camera")
local v3math = require("lib.v3math")

mc.Init(v3math.new(0, 1.5, -2), v3math.new(0, 0, 1), v3math.new(0, 1, 0))

local keys = {}

local function CalcMove (a, b, n)
	local move = 0

	if keys[a] then
		move = move - n
	end

	if keys[b] then
		move = move + n
	end

	return move * Diff
end

function KeyHandler (key, is_down)
	local sym = key.keysym.sym

	if sym == sdl.SDLK_LEFT then
		keys.left = is_down
	elseif sym == sdl.SDLK_RIGHT then
		keys.right = is_down
	end
end

local is_held

function MouseButtonHandler (button, is_down)
	if button.button == 1 then
		is_held = is_down
	end
end

local mx, my = 0, 0

local function Clamp (x)
	return math.min(math.max(x, -10), 10)
end

function MouseMotionHandler (motion)
	if is_held then
		mx, my = Clamp(motion.xrel) * 8 * Diff, Clamp(motion.yrel) * 8 * Diff
	end
end

local dwheel = 0

function MouseWheelHandler (wheel)
	dwheel = wheel.y / 120
end

local x, dx = 0, 1

local CUBE = shapes.GenCube(1)

local function Test ()
	gl.glViewport(0, 0, ww, wh)

	gl.glUseProgram(sp)

	local ddir = dwheel * .2
	local dside = CalcMove("left", "right", .2)

	dwheel = 0

	mc.Update(ddir, dside, -mx, my)

	mx, my, dwheel = 0, 0, 0

	local pos = v3math.new()
	local dir = v3math.new()
	local side = v3math.new()
	local up = v3math.new()

	mc.GetMatrix(pos, dir, side, up)

	xforms.MatrixLoadIdentity(camera)

	local target = v3math.addnew(pos, dir)

	xforms.LookAt(camera, pos[0], pos[1], pos[2], target[0], target[1], target[2], up[0], up[1], up[2])

	xforms.MatrixMultiply(mvp, camera, proj)

	gl.glEnable(gl.GL_DEPTH_TEST)
--gl.glDepthFunc(gl.GL_LESS)
	gl.glEnable(gl.GL_CULL_FACE)
--	gl.glCullFace(gl.GL_BACK)

	gl.glUniformMatrix4fv(loc_mvp, 1, gl.GL_FALSE, mvp[0])
	gl.glVertexAttribPointer(loc_color, 4, gl.GL_FLOAT, gl.GL_FALSE, 0, color)
	gl.glVertexAttribPointer(loc_position, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, CUBE.vertices)
	gl.glEnableVertexAttribArray(loc_color)
	gl.glEnableVertexAttribArray(loc_position)
--	gl.glDrawArrays(gl.GL_TRIANGLE_STRIP, 0, 24)
gl.glDrawElements(gl.GL_TRIANGLES, CUBE.num_indices, gl.GL_UNSIGNED_SHORT, CUBE.indices)

--[[
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glRotatef(5.0, 1.0, 1.0, 1.0)
]]
	gl.glDisableVertexAttribArray(loc_color)
	gl.glDisableVertexAttribArray(loc_position)

	DrawLogoCursor(100 + x, 100)

	if x > 200 then
		dx = -1
	elseif x < -200 then
		dx = 1
	end
	x = x + dx
--	sdl.SDL_Delay(200)
end

gl.glEnable(gl.GL_DEPTH_TEST)
gl.glDepthFunc(gl.GL_LESS)

--[[
Line shader?
-- Identity -> loc_mvp
	gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, 0, 0, (void*)lVerts)
	gl.glDrawArrays(gl.GL_LINES, 0, objects[2].nEdges*2)
]]

while wm:update() do
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	Test()

	egl.eglSwapBuffers(dpy, surf)
end

if cursor_texture[0] ~= 0 then
	gl.glDeleteTextures(1, cursor_texture)
end

egl.eglDestroyContext( dpy, ctx )
egl.eglDestroySurface( dpy, surf )
egl.eglTerminate( dpy )
 
wm:exit()