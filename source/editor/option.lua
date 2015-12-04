
option = {}

function option:OpenSettingFile(id)
    if id == ID.SETTING_EDITOR then
        filer:LoadFile(app:GetPath("source", "setting", "setting-editor.lua"))
    elseif id == ID.SETTING_COMMAND then
        filer:LoadFile(app:GetPath("source", "setting", "setting-command.lua"))
    end
end
