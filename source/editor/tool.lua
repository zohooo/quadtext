
dofile(source .. sep .. "setting" .. sep .. "setting-command.lua")

tool = {}

function SetAllEditorsReadOnly(enable)
    for id, document in pairs(openDocuments) do
        local editor = document.editor
        editor:SetReadOnly(enable)
    end
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
    if not filer:SaveIfModified(editor) then
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
