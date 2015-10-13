
package.path = package.path .. ";?.lua;?/?.lua;"
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;"

require("wx")

sep = package.config:sub(1,1) -- path separator

local maindir, mainlua = "source", "main.lua"
local tail = maindir..sep..mainlua

mainpath = arg and arg[0]
    or debug and debug.getinfo(1, "S").source:sub(2)
    or tail -- assume current working dir is the program dir

local f = wx.wxFileName(mainpath)
if f:Normalize() then
    mainpath = f:GetFullPath():sub(1, -#tail-2)
else
    wx.wxMessageBox("Error in Normalizing Main Path!",
                    "Error Message", wx.wxOK + wx.wxCENTRE)
    return
end

source = mainpath .. sep .. maindir

dofile(source .. sep .. "editor" .. sep .. "gui.lua")
