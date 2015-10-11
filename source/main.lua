
package.path = package.path .. ";?.lua;?/?.lua;"
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;"

local sep = package.config:sub(1,1) -- path separator
local maindir, mainlua = "source", "main.lua"
local tail, length = sep..maindir..sep..mainlua, #maindir + #mainlua + 2

mainpath = "."

if arg[0]:sub(-length) == tail then
    mainpath = arg[0]:sub(1, -length-1)
elseif debug then
    local s = debug.getinfo(1, "S").source
    if s:sub(-length) == tail and s:sub(1,1) == "@" then
        mainpath = s:sub(2, -length-1)
    end
end

source = mainpath .. sep .. maindir

if not wx then dofile(source .. sep .. "editor.lua") end
