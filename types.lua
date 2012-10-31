-- Modules --
local ffi = require("ffi")

-- Exports --
local M = {}

--- DOCME
M.Float3 = ffi.typeof("float[3]")

--- DOCME
M.Float3A = ffi.typeof("float[?][3]")

--- DOCME
M.Float4 = ffi.typeof("float[4]")

--- DOCME
M.Float4A = ffi.typeof("float[?][4]")

-- Export the module.
return M