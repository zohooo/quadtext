
dofile(app:GetPath("source", "editor", "id.lua"))

-- ----------------------------------------------------------------------------
-- Pick some reasonable fixed width fonts to use for the editor

local function PickEditorFont(faceName)
    local size = tonumber(app.setting.editor.fontsize)
    if size < 10 then size = 10 end
    app.font = wx.wxFont(size, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL,
                     wx.wxFONTWEIGHT_NORMAL, false, faceName)
    app.fontItalic = wx.wxFont(size, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_ITALIC,
                           wx.wxFONTWEIGHT_NORMAL, false, faceName)
end

local fontname = app.setting.editor.fontname or "Courier New"
PickEditorFont(tostring(fontname))

-- ----------------------------------------------------------------------------
-- Create the wxFrame
-- ----------------------------------------------------------------------------
frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "QuadText", wx.wxDefaultPosition, wx.wxSize(640, 480))

-- ----------------------------------------------------------------------------
-- Add the child windows to the frame

splitter = wx.wxSplitterWindow(frame, wx.wxID_ANY,
                               wx.wxDefaultPosition, wx.wxDefaultSize,
                               wx.wxSP_3DSASH)

dofile(app:GetPath("source", "editor", "notebook.lua"))
dofile(app:GetPath("source", "editor", "editor.lua"))
dofile(app:GetPath("source", "editor", "console.lua"))

splitter:Initialize(notebook) -- split later to show console

dofile(app:GetPath("source", "editor", "menubar.lua"))
dofile(app:GetPath("source", "editor", "toolbar.lua"))
dofile(app:GetPath("source", "editor", "statusbar.lua"))
dofile(app:GetPath("source", "editor", "encoding.lua"))
dofile(app:GetPath("source", "editor", "filer.lua"))
dofile(app:GetPath("source", "editor", "printing.lua"))
dofile(app:GetPath("source", "editor", "finder.lua"))
dofile(app:GetPath("source", "editor", "tool.lua"))
dofile(app:GetPath("source", "editor", "option.lua"))
dofile(app:GetPath("source", "editor", "help.lua"))
dofile(app:GetPath("source", "editor", "lexer.lua"))
dofile(app:GetPath("source", "editor", "frame.lua"))

frame:ConfigRestoreFramePosition(frame, "MainFrame")

app:RunPlugins("onLoad")

-- ---------------------------------------------------------------------------
-- Load files specified in command line arguments

for _, option in ipairs(app.openFiles) do
    local editor = filer:LoadFile(option.name, nil, true)
    if editor and option.line then
        editor:GotoLine(tonumber(option.line) - 1)
    end
end

if notebook:GetPageCount() == 0 then
    local editor = notebook:AddEditor("untitled.tex")
    notebook:SetupEditor(editor, "tex")
end

-- ---------------------------------------------------------------------------
-- Check if there is some file from another instance to open

local singletonTimer = wx.wxTimer(frame, ID.TIMER_SINGLETON)

local function LoadSingletonFile()
    local config = app:GetConfig()
    if not config then return end
    config:SetPath("/SingleInstance")
    local _, name = config:Read("name","")
    if name and name ~= "" then
        local _, line = config:Read("line", "")
        local editor = filer:LoadFile(name, nil, true)
        frame:Show(false)
        frame:Iconize(true)  -- hack to make it work
        frame:Iconize(false)
        frame:Raise()
        frame:SetFocus()
        if editor and line ~= "" then editor:GotoLine(tonumber(line) - 1) end
    end
    config:DeleteGroup("/SingleInstance")
    config:delete()
end

frame:Connect(ID.TIMER_SINGLETON, wx.wxEVT_TIMER, LoadSingletonFile)

singletonTimer:Start(250);

-- ---------------------------------------------------------------------------
-- Finish creating the frame and show it

frame:SetIcon(wx.wxIcon(app:GetPath("image", "quadtext.png"), wx.wxBITMAP_TYPE_PNG))
frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
