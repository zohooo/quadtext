
dofile(source .. sep .. "setting" .. sep .. "setting-command.lua")

function SetAllEditorsReadOnly(enable)
    for id, document in pairs(openDocuments) do
        local editor = document.editor
        editor:SetReadOnly(enable)
    end
end

function MakeFileName(editor, fullpath)
    if not fullpath then
        fullpath = "file"..tostring(editor)
    end
    return fullpath
end

function SaveIfModified(editor)
    local id = editor:GetId()
    if openDocuments[id].isModified then
        local saved = false
        if not openDocuments[id].fullpath then
            local ret = wx.wxMessageBox("You must save the program before running it.\nPress cancel to abort running.",
                                         "Save file?",  wx.wxOK + wx.wxCANCEL + wx.wxCENTRE, frame)
            if ret == wx.wxOK then
                saved = SaveFileAs(editor)
            end
        else
            saved = SaveFile(editor, openDocuments[id].fullpath)
        end

        if saved then
            openDocuments[id].isModified = false
        else
            return false -- not saved
        end
    end

    return true -- saved
end

function ExpandCommand(cmd, doc)
    cmd = cmd:gsub("#%a+", {
        ["#program"]   = app.programName .. ' ' .. app.scriptName,
        ["#fullpath"]  = doc.fullpath,
        ["#directory"] = doc.directory,
        ["#fullname"]  = doc.fullname,
        ["#basename"]  = doc.basename,
        ["#suffix"]    = doc.suffix,
    })
    return cmd
end

frame:Connect(ID.COMPILE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor();
            if not SaveIfModified(editor) then
                return
            end

            local id = editor:GetId();
            local cmd = app.setting.command.compile
            if cmd then
                cmd = ExpandCommand(cmd, openDocuments[id])
                console:ExecCommand(cmd, openDocuments[id].directory)
            end
        end)
frame:Connect(ID.COMPILE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor ~= nil)
        end)

frame:Connect(ID.PREVIEW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor();
            local id = editor:GetId();
            local cmd = app.setting.command.preview
            if cmd then
                cmd = ExpandCommand(cmd, openDocuments[id])
                console:ExecCommand(cmd, openDocuments[id].directory)
            end
        end)
frame:Connect(ID.PREVIEW, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor ~= nil)
        end)

frame:Connect(ID.SHOWHIDEWINDOW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if splitter:IsSplit() then
                splitter:Unsplit()
            else
                local w, h = frame:GetClientSizeWH()
                splitter:SplitHorizontally(notebook, console, (2 * h) / 3)
            end
        end)
