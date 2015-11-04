
dofile(source .. sep .. "setting" .. sep .. "setting-command.lua")

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
