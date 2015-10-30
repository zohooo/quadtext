
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
