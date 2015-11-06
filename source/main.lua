
app = { version = "0.0.7" }

sep = package.config:sub(1,1) -- path separator

local ext = ""

if sep == "\\" then
    app.osname = "windows"
    ext = "dll"
elseif io.popen("uname -s"):read("*l") == "Darwin" then
    app.osname = "macosx"
    ext = "dylib"
else
    app.osname = "linux"
    ext = "so"
end

package.cpath = "binary" .. sep .. "?." .. ext .. ";" .. package.cpath

require("wx")

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

local _, path = wx.wxGetEnv("PATH")
wx.wxSetEnv("PATH", mainpath .. sep .. "viewer;" .. path)

app.setting = {
    editor = {},
    command = {},
}

-- ---------------------------------------------------------------------------
-- Load the args that this script is run with

if arg then
    local n = 1
    while arg[n-1] do
        n = n - 1
        if arg[n] and not arg[n-1] then app.programName = arg[n] end
    end
    app.scriptName = arg[0]

    app.openFiles = {}
    local option = {}
    for idx = 1, #arg do
        local a = arg[idx]
        if a:sub(1,1) == "-" then
            local i = a:find("=")
            local k, v
            if i then
                k = a:sub(2, i-1)
                v = a:sub(i+1)
            else
                k = a:sub(2)
            end
            if v == "" then v = true end
            if k ~= "" then option[k] = v end
        else
            local f = wx.wxFileName(a)
            if f:Normalize() then
                option.name = f:GetFullPath()
                table.insert(app.openFiles, option)
                option = {}
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Initialize the wxConfig for loading/saving the preferences

function GetConfig()
    local config = wx.wxFileConfig("QuadText")
    if config then
        config:SetRecordDefaults()
    else
        print("Failed to load config file!")
    end
    return config
end

-- ----------------------------------------------------------------------------
-- Single instance

local singleton = wx.wxSingleInstanceChecker()

if singleton:Create(".QuadText-Lock") and singleton:IsAnotherRunning() then
    config = GetConfig()
    config:DeleteGroup("/SingleInstance")
    config:SetPath("/SingleInstance")
    local openfile = app.openFiles[1]
    if openfile then
        for k, v in pairs(openfile) do
            config:Write(k, tostring(v))
        end
        config:Flush()
    end
    return
end

-- ----------------------------------------------------------------------------
-- Plugins

app.plugin = {}

local function LoadLuaFile(path)
    local f, err = loadfile(path)
    if not f then
        print(("Failed to load file: \n%s"):format(err))
    else
        local ok, result = pcall(function() return f() end)
        if not ok then
            print("Failed to call file: " .. path)
        else
            local name = result.name or ""
            if name ~= "" then
                app.plugin[name] = result
            end
        end
    end
end

local function LoadPlugins(path)
    local dir = wx.wxDir()
    dir:Open(path)
    if dir:IsOpened() then
        local found, file = dir:GetFirst("*.lua", wx.wxDIR_FILES)
        while found do
            LoadLuaFile(path .. sep .. file)
            found, file = dir:GetNext()
        end
    else
        print("Error in Loading Plugins!")
    end
end

function RunPlugins(event)
    for _, p in pairs(app.plugin) do
        if type(p[event]) == 'function' then
            local ok, result = pcall(p[event])
            if not ok then
                print(("Failed to handle %s event: \n%s"):format(event, result))
            end
        end
    end
end

source = mainpath .. sep .. maindir

LoadPlugins(source .. sep .. "plugin")

dofile(source .. sep .. "setting" .. sep .. "setting-editor.lua")

local theme = tostring(app.setting.editor.theme or "light")
if theme == "" then theme = "light" end
app.theme = dofile(source .. sep .. "theme" .. sep .. theme .. ".lua")

dofile(source .. sep .. "editor" .. sep .. "gui.lua")
