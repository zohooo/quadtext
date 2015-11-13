
-- ----------------------------------------------------------------------------
-- wxConfig load/save preferences functions

function frame:ConfigRestoreFramePosition(window, windowName)
    local config = app:GetConfig()
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

function frame:ConfigSaveFramePosition(window, windowName)
    local config = app:GetConfig()
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

-- ---------------------------------------------------------------------------
-- Attach callback functions to File menu

frame:Connect(ID.NEW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            filer:NewFile()
        end)

frame:Connect(ID.OPEN, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            filer:OpenFile()
        end)

frame:Connect(ID.SAVE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor   = notebook:GetEditor()
            local id       = editor:GetId()
            local fullpath = openDocuments[id].fullpath
            filer:SaveFile(editor, fullpath)
        end)

frame:Connect(ID.SAVE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = notebook:GetEditor()
            if editor then
                local id = editor:GetId()
                if openDocuments[id] then
                    event:Enable(openDocuments[id].isModified)
                end
            end
        end)

frame:Connect(ID.SAVEAS, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = notebook:GetEditor()
            filer:SaveFileAs(editor)
        end)

frame:Connect(ID.SAVEAS, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = notebook:GetEditor()
            event:Enable(editor ~= nil)
        end)

frame:Connect(ID.SAVEALL, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            filer:SaveAll()
        end)

frame:Connect(ID.SAVEALL, wx.wxEVT_UPDATE_UI,
        function (event)
            local atLeastOneModifiedDocument = false
            for id, document in pairs(openDocuments) do
                if document.isModified then
                    atLeastOneModifiedDocument = true
                    break
                end
            end
            event:Enable(atLeastOneModifiedDocument)
        end)

frame:Connect(ID.CLOSE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = notebook:GetEditor()
            local id     = editor:GetId()
            if filer:SaveModifiedDialog(editor, true) ~= wx.wxID_CANCEL then
                notebook:RemoveEditor(openDocuments[id].index)
            end
        end)

frame:Connect(ID.CLOSE, wx.wxEVT_UPDATE_UI,
        function (event)
            event:Enable(notebook:GetEditor() ~= nil)
        end)

frame:Connect(ID.PRINT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        local editor = notebook:GetEditor()
        -- The default size is too large, this gets ~80 rows for a 12 pt font
        editor:SetPrintMagnification(-2)
        printing:Print()
    end)

frame:Connect(ID.PRINT_PREVIEW, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        local editor = notebook:GetEditor()
        -- The default size is too large, this gets ~80 rows for a 12 pt font
        editor:SetPrintMagnification(-2)
        printing:PrintPreview()
    end)

frame:Connect(ID.PAGE_SETUP, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        printing:PageSetup()
    end)

frame:Connect(ID.EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if not filer:SaveOnExit(true) then return end
            frame:Close() -- will handle wxEVT_CLOSE_WINDOW
        end)

-- ---------------------------------------------------------------------------
-- Attach callback functions to Edit menu

function OnUpdateUIEditMenu(event) -- enable if there is a valid focused editor
    local editor = notebook:GetEditor()
    event:Enable(editor ~= nil)
end

local function OnEditMenu(event)
    local menu_id = event:GetId()
    local editor = notebook:GetEditor()
    if editor == nil then return end

    if     menu_id == ID.CUT       then editor:Cut()
    elseif menu_id == ID.COPY      then editor:Copy()
    elseif menu_id == ID.PASTE     then editor:Paste()
    elseif menu_id == ID.SELECTALL then editor:SelectAll()
    elseif menu_id == ID.UNDO      then editor:Undo()
    elseif menu_id == ID.REDO      then editor:Redo()
    end
end

frame:Connect(ID.CUT, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)

frame:Connect(ID.CUT, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.COPY, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)

frame:Connect(ID.COPY, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.PASTE, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)

frame:Connect(ID.PASTE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = notebook:GetEditor()
            -- buggy GTK clipboard runs eventloop and can generate asserts
            event:Enable(editor and (wx.__WXGTK__ or editor:CanPaste()))
        end)

frame:Connect(ID.SELECTALL, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)

frame:Connect(ID.SELECTALL, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.UNDO, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)

frame:Connect(ID.UNDO, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = notebook:GetEditor()
            event:Enable(editor and editor:CanUndo())
        end)

frame:Connect(ID.REDO, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)

frame:Connect(ID.REDO, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = notebook:GetEditor()
            event:Enable(editor and editor:CanRedo())
        end)

frame:Connect(ID.AUTOCOMPLETE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = notebook:GetEditor()
            if editor then editor:CheckAutoCompletion() end
        end)

frame:Connect(ID.AUTOCOMPLETE, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.AUTOCOMPLETE_ENABLE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            autoCompleteEnable = event:IsChecked()
        end)

frame:Connect(ID.COMMENT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = notebook:GetEditor()
            editor:SwitchComment()
        end)

frame:Connect(ID.COMMENT, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.FOLD, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = notebook:GetEditor()
            editor:SwitchFold()
        end)

frame:Connect(ID.FOLD, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

-- ---------------------------------------------------------------------------
-- Attach callback functions to Search menu

frame:Connect(ID.FIND, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            finder:GetSelectedString()
            finder:Show(false)
        end)

frame:Connect(ID.FIND, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.REPLACE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            finder:GetSelectedString()
            finder:Show(true)
        end)

frame:Connect(ID.REPLACE, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.FINDNEXT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            finder:FindString()
        end)

frame:Connect(ID.FINDNEXT, wx.wxEVT_UPDATE_UI,
        function (event)
            finder:HasText()
        end)

frame:Connect(ID.FINDPREV, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            finder:FindString(true)
        end)

frame:Connect(ID.FINDPREV, wx.wxEVT_UPDATE_UI,
        function (event)
            finder:HasText()
        end)

frame:Connect(ID.GOTOLINE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = notebook:GetEditor()
            local linecur = editor:LineFromPosition(editor:GetCurrentPos())
            local linemax = editor:LineFromPosition(editor:GetLength()) + 1
            local linenum = wx.wxGetNumberFromUser( "Enter line number",
                                                    "1 .. "..tostring(linemax),
                                                    "Goto Line",
                                                    linecur, 1, linemax,
                                                    frame)
            if linenum > 0 then
                editor:GotoLine(linenum-1)
            end
        end)

frame:Connect(ID.GOTOLINE, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.SORT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = notebook:GetEditor()
            local buf = {}
            for line in string.gmatch(editor:GetSelectedText()..'\n', "(.-)\r?\n") do
                table.insert(buf, line)
            end
            if #buf > 0 then
                table.sort(buf)
                editor:ReplaceSelection(table.concat(buf,"\n"))
            end
        end)

frame:Connect(ID.SORT, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

-- ---------------------------------------------------------------------------
-- Attach callback functions to Tool menu

frame:Connect(ID.COMPILE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = notebook:GetEditor();
            tool:Compile(editor)
        end)

frame:Connect(ID.COMPILE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = notebook:GetEditor()
            event:Enable(editor ~= nil)
        end)

frame:Connect(ID.PREVIEW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = notebook:GetEditor();
            tool:Preview(editor)
        end)

frame:Connect(ID.PREVIEW, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = notebook:GetEditor()
            event:Enable(editor ~= nil)
        end)

frame:Connect(ID.SHOWHIDEWINDOW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            console:SplitShow(event:IsChecked())
        end)

frame:Connect(ID.CLEAROUTPUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            console:ClearOutput()
        end)

-- ---------------------------------------------------------------------------
-- Attach callback functions to Option menu

frame:Connect(ID.SETTING_EDITOR, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local id = event:GetId()
            option:OpenSettingFile(id)
        end)

frame:Connect(ID.SETTING_COMMAND, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local id = event:GetId()
            option:OpenSettingFile(id)
        end)

-- ---------------------------------------------------------------------------
-- Attach callback functions to Help menu

frame:Connect(ID.ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        help:DisplayAbout()
    end)

frame:Connect(ID.HELP_PROJECT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function(event)
        help:OpenHelpPage(event:GetId())
    end)

frame:Connect(ID.HELP_SUPPORT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function(event)
        help:OpenHelpPage(event:GetId())
    end)
