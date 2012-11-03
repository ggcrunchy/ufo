local ffi = require("ffi")
local bit = require("bit")
local egl = require( "ffi/EGL" )
local gl  = require( "ffi/OpenGLES2" )
local sdl = require( "ffi/sdl" )
local window = require("window")
   
local ww, wh = 512, 512
--[[
local KeyHandler
local MouseActionHandler
local MouseMotionHandler
local MouseWheelHandler

local Diff, Init, Term
]]
--
local function NoOp () end

local Funcs = setmetatable({}, {
	__index = function() return NoOp end
})
local Draw
-- Use SDL for windowing and events
local function InitSDL()
--[=[
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
]=]
	window.SetMode_SDL(ww, wh)
   Draw = true
   local event = ffi.new( "SDL_Event" )
   local prev_time, curr_time, fps = 0, 0, 0
   return {
--      window = window,
--      display = display,
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
		  Funcs.pre_update(curr_time - prev_time)
		  while sdl.SDL_PollEvent( event ) ~= 0 do
		     if event.type == sdl.SDL_QUIT then
			return false
		     end
		     if event.type == sdl.SDL_KEYUP and event.key.keysym.sym == sdl.SDLK_ESCAPE then
			event.type = sdl.SDL_QUIT
			sdl.SDL_PushEvent( event )
			 elseif event.type == sdl.SDL_KEYUP or event.type == sdl.SDL_KEYDOWN then
--				KeyHandler(event.key, event.type == sdl.SDL_KEYDOWN)
				Funcs.key(event.key, event.type == sdl.SDL_KEYDOWN)
			elseif event.type == sdl.SDL_MOUSEBUTTONDOWN or event.type == sdl.SDL_MOUSEBUTTONUP then
--				MouseButtonHandler
				Funcs.mouse_button(event.button, event.type == sdl.SDL_MOUSEBUTTONDOWN)
			elseif event.type == sdl.SDL_MOUSEWHEEL then
--				MouseWheelHandler
				Funcs.mouse_wheel(event.wheel)
			 elseif event.type == sdl.SDL_MOUSEMOTION then
--				MouseMotionHandler
				Funcs.mouse_motion(event.motion)
			elseif event.type == sdl.SDL_WINDOWEVENT then
				if event.window.event == sdl.SDL_WINDOWEVENT_MINIMIZED then
			--		print("MINIM")
					--Term()
					Draw = false
				elseif event.window.event == sdl.SDL_WINDOWEVENT_RESTORED then
--					Init()
	--				print(tostring(event.window.event))
	Draw = true
					window.Reload()
				end
			 end
		  end
		  return true 
	       end,
      exit = function()
		window.Close()
		sdl.SDL_Quit() 
	     end,
   }
end

local wm = InitSDL()
--[=[
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

local surf, ctx, r
local DDD
function Init ()
DDD = false
--local 
surf     = egl.eglCreateWindowSurface( dpy, cfg[0], wm.window, nil )
--local 
ctx      = egl.eglCreateContext(       dpy, cfg[0], nil, ctx_attr )
--local 
r        = egl.eglMakeCurrent(         dpy,   surf, surf, ctx )

print('surf/ctx', surf, r0, ctx, r, n_cfg[0])
end
local CC
function Term ()
DDD= true
--[[
if CC[0] ~= 0 then
	gl.glDeleteTextures(1, CC)
	CC[0] = 0
end]]
egl.eglDestroyContext( dpy, ctx )
egl.eglDestroySurface( dpy, surf )
end

Init()
]=]
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

require("driver").Start(Funcs, ww, wh)

gl.glEnable(gl.GL_DEPTH_TEST)
gl.glDepthFunc(gl.GL_LESS)
local WasDraw=Draw
while wm:update() do
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	Funcs.update()

	if Draw then
		window.SwapBuffers()--WasDraw)
	end
	WasDraw=Draw
--	Test()
--[[
if not DDD then
local d = egl.eglGetError()
	egl.eglSwapBuffers(dpy, surf)

local e = egl.eglGetError()
if d~=egl.EGL_SUCCESS or e~=egl.EGL_SUCCESS then
print("OH NOES", ("%x"):format(d), ("%x"):format(e))
end
end
]]
end
--[[
Term()

egl.eglTerminate( dpy )
 ]]
wm:exit()