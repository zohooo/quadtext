
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

-- Generate a unique new wxWindowID
local ID_IDCOUNTER = wx.wxID_HIGHEST + 1
function NewID()
    ID_IDCOUNTER = ID_IDCOUNTER + 1
    return ID_IDCOUNTER
end

-- Markers for editor marker margin
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
console          = nil    -- wxStyledTextCtrl log window for messages

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
editorID         = 100    -- window id to create editor pages with, incremented for new editors
exitingProgram   = false  -- are we currently exiting, ID_EXIT
autoCompleteEnable = true -- value of ID_AUTOCOMPLETE_ENABLE menu item
wxkeywords       = nil    -- a string of the keywords for scintilla of wxLua's wx.XXX items
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

if wx.__WXMSW__ then
    PickEditorFont("Andale Mono")
else
    PickEditorFont("")
end

-- ----------------------------------------------------------------------------
-- Create the wxFrame
-- ----------------------------------------------------------------------------
frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "QuadText", wx.wxDefaultPosition, wx.wxSize(640, 480))

statusBar = frame:CreateStatusBar( 4 )
local status_txt_width = statusBar:GetTextExtent("OVRW")
frame:SetStatusWidths({-1, status_txt_width, status_txt_width, status_txt_width*5})
frame:SetStatusText("Welcome to QuadText")

toolBar = frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)
-- note: Ususally the bmp size isn't necessary, but the HELP icon is not the right size in MSW
toolBmpSize = toolBar:GetToolBitmapSize()

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
                                            LoadFile(filenames[i], nil, true)
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

console = wxstc.wxStyledTextCtrl(splitter, wx.wxID_ANY)
console:Show(false)
console:SetFont(font)
console:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, font)
console:StyleClearAll()
console:SetMarginWidth(1, 16) -- marker margin
console:SetMarginType(1, wxstc.wxSTC_MARGIN_SYMBOL);
console:MarkerDefine(CURRENT_LINE_MARKER, wxstc.wxSTC_MARK_ARROWS, wx.wxBLACK, wx.wxWHITE)
console:SetReadOnly(true)

splitter:Initialize(notebook) -- split later to show console

-- ----------------------------------------------------------------------------
-- wxConfig load/save preferences functions

function ConfigRestoreFramePosition(window, windowName)
    local config = GetConfig()
    if not config then return end

    config:SetPath("/"..windowName)

    local _, s = config:Read("s", -1)
    local _, x = config:Read("x", 0)
    local _, y = config:Read("y", 0)
    local _, w = config:Read("w", 0)
    local _, h = config:Read("h", 0)

    if (s ~= -1) and (s ~= 1) and (s ~= 2) then
        local clientX, clientY, clientWidth, clientHeight
        clientX, clientY, clientWidth, clientHeight = wx.wxClientDisplayRect()

        if x < clientX then x = clientX end
        if y < clientY then y = clientY end

        if w > clientWidth  then w = clientWidth end
        if h > clientHeight then h = clientHeight end

        window:SetSize(x, y, w, h)
    elseif s == 1 then
        window:Maximize(true)
    end

    config:delete() -- always delete the config
end

function ConfigSaveFramePosition(window, windowName)
    local config = GetConfig()
    if not config then return end

    config:SetPath("/"..windowName)

    local s    = 0
    local w, h = window:GetSizeWH()
    local x, y = window:GetPositionXY()

    if window:IsMaximized() then
        s = 1
    elseif window:IsIconized() then
        s = 2
    end

    config:Write("s", s)

    if s == 0 then
        config:Write("x", x)
        config:Write("y", y)
        config:Write("w", w)
        config:Write("h", h)
    end

    config:delete() -- always delete the config
end

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
        IsFileAlteredOnDisk(editor)
    end
    UpdateStatusText(editor) -- update even if nil
end

-- ----------------------------------------------------------------------------
-- Update the statusbar text of the frame using the given editor.
--  Only update if the text has changed.
statusTextTable = { "OVR?", "R/O?", "Cursor Pos" }

function UpdateStatusText(editor)
    local texts = { "", "", "" }
    if frame and editor then
        local pos  = editor:GetCurrentPos()
        local line = editor:LineFromPosition(pos)
        local col  = 1 + pos - editor:PositionFromLine(line)

        texts = { iff(editor:GetOvertype(), "OVR", "INS"),
                  iff(editor:GetReadOnly(), "R/O", "R/W"),
                  "Ln "..tostring(line + 1).." Col "..tostring(col) }
    end

    if frame then
        for n = 1, 3 do
            if (texts[n] ~= statusTextTable[n]) then
                frame:SetStatusText(texts[n], n)
                statusTextTable[n] = texts[n]
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Get file modification time, returns a wxDateTime (check IsValid) or nil if
--   the file doesn't exist
function GetFileModTime(fullpath)
    if fullpath and (string.len(fullpath) > 0) then
        local fn = wx.wxFileName(fullpath)
        if fn:FileExists() then
            return fn:GetModificationTime()
        end
    end

    return nil
end

-- Check if file is altered, show dialog to reload it
function IsFileAlteredOnDisk(editor)
    if not editor then return end

    local id = editor:GetId()
    if openDocuments[id] then
        local fullpath   = openDocuments[id].fullpath
        local fullname   = openDocuments[id].fullname
        local oldModTime = openDocuments[id].modTime

        if fullpath and (string.len(fullpath) > 0) and oldModTime and oldModTime:IsValid() then
            local modTime = GetFileModTime(fullpath)
            if modTime == nil then
                openDocuments[id].modTime = nil
                wx.wxMessageBox(fullname.." is no longer on the disk.",
                                "wxLua Message",
                                wx.wxOK + wx.wxCENTRE, frame)
            elseif modTime:IsValid() and oldModTime:IsEarlierThan(modTime) then
                local ret = wx.wxMessageBox(fullname.." has been modified on disk.\nDo you want to reload it?",
                                            "wxLua Message",
                                            wx.wxYES_NO + wx.wxCENTRE, frame)
                if ret ~= wx.wxYES or LoadFile(fullpath, editor, true) then
                    openDocuments[id].modTime = nil
                end
            end
        end
    end
end

-- Set if the document is modified and update the notebook page text
function SetDocumentModified(id, modified)
    local pageText = openDocuments[id].fullname or "untitled.tex"

    if modified then
        pageText = "* "..pageText
    end

    openDocuments[id].isModified = modified
    notebook:SetPageText(openDocuments[id].index, pageText)
end

-- ----------------------------------------------------------------------------
-- Create an editor and add it to the notebook
function CreateEditor(name)
    local editor = wxstc.wxStyledTextCtrl(notebook, editorID,
                                          wx.wxDefaultPosition, wx.wxDefaultSize,
                                          wx.wxSUNKEN_BORDER)

    editorID = editorID + 1 -- increment so they're always unique

    editor:SetBufferedDraw(true)
    editor:StyleClearAll()

    editor:SetFont(font)
    editor:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, font)
    for i = 0, 32 do
        editor:StyleSetFont(i, font)
    end

    editor:SetUseTabs(false)
    editor:SetTabWidth(4)
    editor:SetIndent(4)
    editor:SetIndentationGuides(true)

    local wrapmode = app.setting.editor.wrapmode or 1
    editor:SetWrapMode(tonumber(wrapmode))

    editor:SetVisiblePolicy(wxstc.wxSTC_VISIBLE_SLOP, 3)
    --editor:SetXCaretPolicy(wxstc.wxSTC_CARET_SLOP, 10)
    --editor:SetYCaretPolicy(wxstc.wxSTC_CARET_SLOP, 3)

    editor:SetMarginWidth(0, editor:TextWidth(32, "99999_")) -- line # margin

    editor:SetMarginWidth(1, 16) -- marker margin
    editor:SetMarginType(1, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginSensitive(1, true)

    editor:MarkerDefine(CURRENT_LINE_MARKER, wxstc.wxSTC_MARK_ARROW,     wx.wxBLACK, wx.wxGREEN)

    editor:SetMarginWidth(2, 16) -- fold margin
    editor:SetMarginType(2, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginMask(2, wxstc.wxSTC_MASK_FOLDERS)
    editor:SetMarginSensitive(2, true)

    editor:SetFoldFlags(wxstc.wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED +
                        wxstc.wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED)

    editor:SetProperty("fold", "1")
    editor:SetProperty("fold.compact", "1")
    editor:SetProperty("fold.comment", "1")

    local grey = wx.wxColour(128, 128, 128)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEROPEN,    wxstc.wxSTC_MARK_BOXMINUS, wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDER,        wxstc.wxSTC_MARK_BOXPLUS,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERSUB,     wxstc.wxSTC_MARK_VLINE,    wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERTAIL,    wxstc.wxSTC_MARK_LCORNER,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEREND,     wxstc.wxSTC_MARK_BOXPLUSCONNECTED,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEROPENMID, wxstc.wxSTC_MARK_BOXMINUSCONNECTED, wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERMIDTAIL, wxstc.wxSTC_MARK_TCORNER,  wx.wxWHITE, grey)
    grey:delete()

    editor:Connect(wxstc.wxEVT_STC_MARGINCLICK,
            function (event)
                local line = editor:LineFromPosition(event:GetPosition())
                local margin = event:GetMargin()
                if margin == 2 then
                    if wx.wxGetKeyState(wx.WXK_SHIFT) and wx.wxGetKeyState(wx.WXK_CONTROL) then
                        FoldSome()
                    else
                        local level = editor:GetFoldLevel(line)
                        if HasBit(level, wxstc.wxSTC_FOLDLEVELHEADERFLAG) then
                            editor:ToggleFold(line)
                        end
                    end
                end
            end)

    editor:Connect(wxstc.wxEVT_STC_CHARADDED,
            function (event)
                -- auto-indent
                local ch = event:GetKey()
                if (ch == char_CR) or (ch == char_LF) then
                    local pos = editor:GetCurrentPos()
                    local line = editor:LineFromPosition(pos)

                    if (line > 0) and (editor:LineLength(line) == 0) then
                        local indent = editor:GetLineIndentation(line - 1)
                        if indent > 0 then
                            editor:SetLineIndentation(line, indent)
                            editor:GotoPos(pos + indent)
                        end
                    end
                elseif autoCompleteEnable then -- code completion prompt
                    local pos = editor:GetCurrentPos()
                    local start_pos = editor:WordStartPosition(pos, true)
                    -- must have "wx.X" otherwise too many items
                    if (pos - start_pos > 0) and (start_pos > 2) then
                        local range = editor:GetTextRange(start_pos-3, start_pos)
                        if range == "wx." then
                            local commandEvent = wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED,
                                                                   ID_AUTOCOMPLETE)
                            wx.wxPostEvent(frame, commandEvent)
                        end
                    end
                end
            end)

    editor:Connect(wxstc.wxEVT_STC_USERLISTSELECTION,
            function (event)
                local pos = editor:GetCurrentPos()
                local start_pos = editor:WordStartPosition(pos, true)
                editor:SetSelection(start_pos, pos)
                editor:ReplaceSelection(event:GetText())
            end)

    editor:Connect(wxstc.wxEVT_STC_SAVEPOINTREACHED,
            function (event)
                SetDocumentModified(editor:GetId(), false)
            end)

    editor:Connect(wxstc.wxEVT_STC_SAVEPOINTLEFT,
            function (event)
                SetDocumentModified(editor:GetId(), true)
            end)

    editor:Connect(wxstc.wxEVT_STC_UPDATEUI,
            function (event)
                UpdateStatusText(editor)
            end)

    editor:Connect(wx.wxEVT_SET_FOCUS,
            function (event)
                event:Skip()
                if in_evt_focus or exitingProgram then return end
                in_evt_focus = true
                IsFileAlteredOnDisk(editor)
                in_evt_focus = false
            end)

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

function IsLuaFile(fullpath)
    return fullpath and (string.len(fullpath) > 4) and
           (string.lower(string.sub(fullpath, -4)) == ".lua")
end

function CreateAutoCompList(key_) -- much faster than iterating the wx. table
    local key = "wx."..key_;
    local a, b = string.find(wxkeywords, key, 1, 1)
    local key_list = ""

    while a do
        local c, d = string.find(wxkeywords, " ", b, 1)
        key_list = key_list..string.sub(wxkeywords, a+3, c or -1)
        a, b = string.find(wxkeywords, key, d, 1)
    end

    return key_list
end

-- force all the wxEVT_UPDATE_UI handlers to be called
function UpdateUIMenuItems()
    if frame and frame:GetMenuBar() then
        for n = 0, frame:GetMenuBar():GetMenuCount()-1 do
            frame:GetMenuBar():GetMenu(n):UpdateUI()
        end
    end
end

menuBar = wx.wxMenuBar()

dofile(source .. sep .. "editor" .. sep .. "file.lua")
dofile(source .. sep .. "editor" .. sep .. "edit.lua")
dofile(source .. sep .. "editor" .. sep .. "search.lua")
dofile(source .. sep .. "editor" .. sep .. "tool.lua")
dofile(source .. sep .. "editor" .. sep .. "option.lua")
dofile(source .. sep .. "editor" .. sep .. "help.lua")
dofile(source .. sep .. "editor" .. sep .. "lexer.lua")

-- ---------------------------------------------------------------------------
-- Attach the handler for closing the frame

function CloseWindow(event)
    exitingProgram = true -- don't handle focus events

    if not SaveOnExit(event:CanVeto()) then
        event:Veto()
        exitingProgram = false
        return
    end

    RunPlugins("onClose")

    ConfigSaveFramePosition(frame, "MainFrame")
    event:Skip()
end
frame:Connect(wx.wxEVT_CLOSE_WINDOW, CloseWindow)

-- ---------------------------------------------------------------------------
-- Finish creating the frame and show it

frame:SetMenuBar(menuBar)
toolBar:Realize()
ConfigRestoreFramePosition(frame, "MainFrame")

RunPlugins("onLoad")

-- ---------------------------------------------------------------------------
-- Load files specified in command line arguments

for _, option in ipairs(app.openFiles) do
    local editor = LoadFile(option.name, nil, true)
    if editor and option.line then
        editor:GotoLine(tonumber(option.line) - 1)
    end
end

if notebook:GetPageCount() == 0 then
    local editor = CreateEditor("untitled.tex")
    SetupStyles(editor, "tex")
end

-- ---------------------------------------------------------------------------
-- Check if there is some file from another instance to open

local ID_SINGLETON = NewID()
local singletonTimer = wx.wxTimer(frame, ID_SINGLETON)

local function LoadSingletonFile()
    local config = GetConfig()
    if not config then return end
    config:SetPath("/SingleInstance")
    local _, name = config:Read("name","")
    if name and name ~= "" then
        local _, line = config:Read("line", "")
        local editor = LoadFile(name, nil, true)
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

frame:Connect(ID_SINGLETON, wx.wxEVT_TIMER, LoadSingletonFile)

singletonTimer:Start(250);

--frame:SetIcon(wxLuaEditorIcon) --FIXME add this back
frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
