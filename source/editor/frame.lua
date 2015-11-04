
frame:Connect(ID.NEW, wx.wxEVT_COMMAND_MENU_SELECTED, NewFile)

frame:Connect(ID.OPEN, wx.wxEVT_COMMAND_MENU_SELECTED, OpenFile)

frame:Connect(ID.SAVE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor   = GetEditor()
            local id       = editor:GetId()
            local fullpath = openDocuments[id].fullpath
            SaveFile(editor, fullpath)
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
            SaveFileAs(editor)
        end)

frame:Connect(ID.SAVEAS, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor ~= nil)
        end)

frame:Connect(ID.SAVEALL, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            SaveAll()
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
            if SaveModifiedDialog(editor, true) ~= wx.wxID_CANCEL then
                RemovePage(openDocuments[id].index)
            end
        end)

frame:Connect(ID.CLOSE, wx.wxEVT_UPDATE_UI,
        function (event)
            event:Enable(GetEditor() ~= nil)
        end)

frame:Connect(ID.EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if not SaveOnExit(true) then return end
            frame:Close() -- will handle wxEVT_CLOSE_WINDOW
        end)
