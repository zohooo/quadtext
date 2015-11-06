
dofile(source .. sep .. "setting" .. sep .. "setting-command.lua")

tool = {}

function SetAllEditorsReadOnly(enable)
    for id, document in pairs(openDocuments) do
        local editor = document.editor
        editor:SetReadOnly(enable)
    end
end

function SaveIfModified(editor)
    local id = editor:GetId()
    if openDocuments[id].isModified then
        local saved = false
        if not openDocuments[id].fullpath then
            local ret = wx.wxMessageBox("You must save the program before running it.\nPress cancel to abort running.",
                                         "Save file?",  wx.wxOK + wx.wxCANCEL + wx.wxCENTRE, frame)
            if ret == wx.wxOK then
                saved = filer:SaveFileAs(editor)
            end
        else
            saved = filer:SaveFile(editor, openDocuments[id].fullpath)
        end

        if saved then
            openDocuments[id].isModified = false
        else
            return false -- not saved
        end
    end

    return true -- saved
end

function tool:ExpandCommand(cmd, doc)
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

function tool:Compile(editor)
    if not SaveIfModified(editor) then
        return
    end
    local id = editor:GetId();
    local cmd = app.setting.command.compile
    if cmd then
        cmd = tool:ExpandCommand(cmd, openDocuments[id])
        console:ExecCommand(cmd, openDocuments[id].directory)
    end
end

function tool:Preview(editor)
    local id = editor:GetId();
    local cmd = app.setting.command.preview
    if cmd then
        cmd = tool:ExpandCommand(cmd, openDocuments[id])
        console:RunProgram(cmd, openDocuments[id].directory)
    end
end
