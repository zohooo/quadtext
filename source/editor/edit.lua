-- ---------------------------------------------------------------------------
-- Create the Edit menu and attach the callback functions

editMenu = wx.wxMenu{
        { ID.CUT,       "Cu&t\tCtrl-X",        "Cut selected text to clipboard" },
        { ID.COPY,      "&Copy\tCtrl-C",       "Copy selected text to the clipboard" },
        { ID.PASTE,     "&Paste\tCtrl-V",      "Insert clipboard text at cursor" },
        { ID.SELECTALL, "Select A&ll\tCtrl-A", "Select all text in the editor" },
        { },
        { ID.UNDO,      "&Undo\tCtrl-Z",       "Undo the last action" },
        { ID.REDO,      "&Redo\tCtrl-Y",       "Redo the last action undone" },
        { },
        { ID.AUTOCOMPLETE,        "Complete &Identifier\tCtrl+K", "Complete the current identifier" },
        { ID.AUTOCOMPLETE_ENABLE, "Auto complete Identifiers",    "Auto complete while typing", wx.wxITEM_CHECK },
        { },
        { ID.COMMENT, "C&omment/Uncomment\tCtrl-Q", "Comment or uncomment current or selected lines"},
        { },
        { ID.FOLD,    "&Fold/Unfold all\tF12", "Fold or unfold all code folds"} }
menuBar:Append(editMenu, "&Edit")

editMenu:Check(ID.AUTOCOMPLETE_ENABLE, autoCompleteEnable)

toolBar:AddSeparator()
toolBar:AddTool(ID.CUT, "Cut",
                wx.wxArtProvider.GetBitmap(wx.wxART_CUT, wx.wxART_MENU, toolBmpSize),
                "Cut the selection")
toolBar:AddTool(ID.COPY, "Copy",
                wx.wxArtProvider.GetBitmap(wx.wxART_COPY, wx.wxART_MENU, toolBmpSize),
                "Copy the selection")
toolBar:AddTool(ID.PASTE, "Paste",
                wx.wxArtProvider.GetBitmap(wx.wxART_PASTE, wx.wxART_MENU, toolBmpSize),
                "Paste text from the clipboard")
toolBar:AddSeparator()
toolBar:AddTool(ID.UNDO, "Undo",
                wx.wxArtProvider.GetBitmap(wx.wxART_UNDO, wx.wxART_MENU, toolBmpSize),
                "Undo last edit")
toolBar:AddTool(ID.REDO, "Redo",
                wx.wxArtProvider.GetBitmap(wx.wxART_REDO, wx.wxART_MENU, toolBmpSize),
                "Redo last undo")

function OnUpdateUIEditMenu(event) -- enable if there is a valid focused editor
    local editor = GetEditor()
    event:Enable(editor ~= nil)
end

function OnEditMenu(event)
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
            if (editor == nil) then return end
            local pos = editor:GetCurrentPos()
            local start_pos = editor:WordStartPosition(pos, true)
            -- must have "wx.XX" otherwise too many items
            if (pos - start_pos > 2) and (start_pos > 2) then
                local range = editor:GetTextRange(start_pos-3, start_pos)
                if range == "wx." then
                    local key = editor:GetTextRange(start_pos, pos)
                    local userList = CreateAutoCompList(key)
                    if userList and string.len(userList) > 0 then
                        editor:UserListShow(1, userList)
                    end
                end
            end
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
