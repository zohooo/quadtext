
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
            local editor   = GetEditor()
            local id       = editor:GetId()
            local fullpath = openDocuments[id].fullpath
            filer:SaveFile(editor, fullpath)
        end)

frame:Connect(ID.SAVE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            if editor then
                local id = editor:GetId()
                if openDocuments[id] then
                    event:Enable(openDocuments[id].isModified)
                end
            end
        end)

frame:Connect(ID.SAVEAS, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            filer:SaveFileAs(editor)
        end)

frame:Connect(ID.SAVEAS, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
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
            local editor = GetEditor()
            local id     = editor:GetId()
            if filer:SaveModifiedDialog(editor, true) ~= wx.wxID_CANCEL then
                filer:RemovePage(openDocuments[id].index)
            end
        end)

frame:Connect(ID.CLOSE, wx.wxEVT_UPDATE_UI,
        function (event)
            event:Enable(GetEditor() ~= nil)
        end)

frame:Connect(ID.EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if not filer:SaveOnExit(true) then return end
            frame:Close() -- will handle wxEVT_CLOSE_WINDOW
        end)

-- ---------------------------------------------------------------------------
-- Attach callback functions to Edit menu

function OnUpdateUIEditMenu(event) -- enable if there is a valid focused editor
    local editor = GetEditor()
    event:Enable(editor ~= nil)
end

local function OnEditMenu(event)
    local menu_id = event:GetId()
    local editor = GetEditor()
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
            local editor = GetEditor()
            -- buggy GTK clipboard runs eventloop and can generate asserts
            event:Enable(editor and (wx.__WXGTK__ or editor:CanPaste()))
        end)

frame:Connect(ID.SELECTALL, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)

frame:Connect(ID.SELECTALL, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.UNDO, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)

frame:Connect(ID.UNDO, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor and editor:CanUndo())
        end)

frame:Connect(ID.REDO, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)

frame:Connect(ID.REDO, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor and editor:CanRedo())
        end)

frame:Connect(ID.AUTOCOMPLETE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            if editor then editor:CheckAutoCompletion() end
        end)

frame:Connect(ID.AUTOCOMPLETE, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.AUTOCOMPLETE_ENABLE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            autoCompleteEnable = event:IsChecked()
        end)

frame:Connect(ID.COMMENT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            editor:SwitchComment()
        end)

frame:Connect(ID.COMMENT, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID.FOLD, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            editor:SwitchFold()
        end)

frame:Connect(ID.FOLD, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)
