
-- Equivalent to C's "cond ? a : b", all terms will be evaluated
function iff(cond, a, b) if cond then return a else return b end end

-- Does the num have all the bits in value
function HasBit(value, num)
    for n = 32, 0, -1 do
        local b = 2^n
        local num_b = num - b
        local value_b = value - b
        if num_b >= 0 then
            num = num_b
        else
            return true -- already tested bits in num
        end
        if value_b >= 0 then
            value = value_b
        end
        if (num_b >= 0) and (value_b < 0) then
            return false
        end
    end

    return true
end

dofile(source .. sep .. "editor" .. sep .. "id.lua")

-- Markers for editor marker margin
ERROR_MARKER = 1
CURRENT_LINE_MARKER       = 2
CURRENT_LINE_MARKER_VALUE = 4 -- = 2^CURRENT_LINE_MARKER

-- ASCII values for common chars
local char_CR  = string.byte("\r")
local char_LF  = string.byte("\n")
local char_Tab = string.byte("\t")
local char_Sp  = string.byte(" ")

-- wxWindow variables
frame            = nil    -- wxFrame the main top level window
splitter         = nil    -- wxSplitterWindow for the notebook and console
notebook         = nil    -- wxNotebook of editors

in_evt_focus     = false  -- true when in editor focus event to avoid recursion
openDocuments    = {}     -- open notebook editor documents[winId] = {
                          --   editor     = wxStyledTextCtrl,
                          --   index      = wxNotebook page index,
                          --   fullpath   = full filepath, nil if not saved,
                          --   fullname   = full filename with extension
                          --   directory  = filepath without filename
                          --   basename   = filename without extension
                          --   suffix     = filename extension
                          --   modTime    = wxDateTime of disk file or nil,
                          --   isModified = bool is the document modified? }
ignoredFilesList = {}
exitingProgram   = false  -- are we currently exiting, ID.EXIT
autoCompleteEnable = true -- value of ID.AUTOCOMPLETE_ENABLE menu item
font             = nil    -- fonts to use for the editor
fontItalic       = nil

-- ----------------------------------------------------------------------------

-- Pick some reasonable fixed width fonts to use for the editor

local function PickEditorFont(faceName)
    local size = tonumber(app.setting.editor.fontsize)
    if size < 10 then size = 10 end
    font = wx.wxFont(size, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL,
                     wx.wxFONTWEIGHT_NORMAL, false, faceName)
    fontItalic = wx.wxFont(size, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_ITALIC,
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

notebook = wx.wxNotebook(splitter, wx.wxID_ANY,
                         wx.wxDefaultPosition, wx.wxDefaultSize,
                         wx.wxCLIP_CHILDREN)

notebookFileDropTarget = wx.wxLuaFileDropTarget();
notebookFileDropTarget.OnDropFiles = function(self, x, y, filenames)
                                        for i = 1, #filenames do
                                            filer:LoadFile(filenames[i], nil, true)
                                        end
                                        return true
                                     end
notebook:SetDropTarget(notebookFileDropTarget)

notebook:Connect(wx.wxEVT_COMMAND_NOTEBOOK_PAGE_CHANGED,
        function (event)
            if not exitingProgram then
                SetEditorSelection(event:GetSelection())
            end
            event:Skip() -- skip to let page change
        end)

dofile(source .. sep .. "editor" .. sep .. "console.lua")

splitter:Initialize(notebook) -- split later to show console

-- ----------------------------------------------------------------------------
-- Get/Set notebook editor page, use nil for current page, returns nil if none
function GetEditor(selection)
    local editor = nil
    if selection == nil then
        selection = notebook:GetSelection()
    end
    if (selection >= 0) and (selection < notebook:GetPageCount()) then
        editor = notebook:GetPage(selection):DynamicCast("wxStyledTextCtrl")
    end
    return editor
end

-- init new notebook page selection, use nil for current page
function SetEditorSelection(selection)
    local editor = GetEditor(selection)
    if editor then
        editor:SetFocus()
        editor:SetSTCFocus(true)
        filer:IsFileAlteredOnDisk(editor)
    end
    statusbar:UpdateStatusText(editor) -- update even if nil
end

-- ----------------------------------------------------------------------------
-- Set if the document is modified and update the notebook page text
function SetDocumentModified(id, modified)
    local pageText = openDocuments[id].fullname or "untitled.tex"

    if modified then
        pageText = "* "..pageText
    end

    openDocuments[id].isModified = modified
    notebook:SetPageText(openDocuments[id].index, pageText)
end

dofile(source .. sep .. "editor" .. sep .. "editor.lua")

-- ----------------------------------------------------------------------------
-- Create an editor and add it to the notebook
function CreateEditor(name)
    local editor = app:CreateEditor(notebook, wx.wxDefaultPosition,
                                    wx.wxDefaultSize, wx.wxSUNKEN_BORDER)

    if notebook:AddPage(editor, name, true) then
        local id            = editor:GetId()
        local document      = {}
        document.editor     = editor
        document.index      = notebook:GetSelection()
        document.fullname   = nil
        document.fullpath   = nil
        document.modTime    = nil
        document.isModified = false
        openDocuments[id]   = document
    end

    return editor
end

-- force all the wxEVT_UPDATE_UI handlers to be called
function UpdateUIMenuItems()
    if frame and frame:GetMenuBar() then
        for n = 0, frame:GetMenuBar():GetMenuCount()-1 do
            frame:GetMenuBar():GetMenu(n):UpdateUI()
        end
    end
end

dofile(source .. sep .. "editor" .. sep .. "menubar.lua")
dofile(source .. sep .. "editor" .. sep .. "toolbar.lua")
dofile(source .. sep .. "editor" .. sep .. "statusbar.lua")
dofile(source .. sep .. "editor" .. sep .. "encoding.lua")
dofile(source .. sep .. "editor" .. sep .. "filer.lua")
dofile(source .. sep .. "editor" .. sep .. "printing.lua")
dofile(source .. sep .. "editor" .. sep .. "finder.lua")
dofile(source .. sep .. "editor" .. sep .. "tool.lua")
dofile(source .. sep .. "editor" .. sep .. "option.lua")
dofile(source .. sep .. "editor" .. sep .. "help.lua")
dofile(source .. sep .. "editor" .. sep .. "lexer.lua")
dofile(source .. sep .. "editor" .. sep .. "frame.lua")

-- ---------------------------------------------------------------------------
-- Attach the handler for closing the frame

function CloseWindow(event)
    exitingProgram = true -- don't handle focus events

    if not filer:SaveOnExit(event:CanVeto()) then
        event:Veto()
        exitingProgram = false
        return
    end

    RunPlugins("onClose")

    frame:ConfigSaveFramePosition(frame, "MainFrame")
    event:Skip()
end
frame:Connect(wx.wxEVT_CLOSE_WINDOW, CloseWindow)

-- ---------------------------------------------------------------------------
-- Finish creating the frame and show it

frame:ConfigRestoreFramePosition(frame, "MainFrame")

RunPlugins("onLoad")

-- ---------------------------------------------------------------------------
-- Load files specified in command line arguments

for _, option in ipairs(app.openFiles) do
    local editor = filer:LoadFile(option.name, nil, true)
    if editor and option.line then
        editor:GotoLine(tonumber(option.line) - 1)
    end
end

if notebook:GetPageCount() == 0 then
    local editor = CreateEditor("untitled.tex")
    frame:SetupEditor(editor, "tex")
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

--frame:SetIcon(wxLuaEditorIcon) --FIXME add this back
frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
