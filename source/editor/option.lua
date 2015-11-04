
function OpenSettingFile(event)
    local id = event:GetId()
    if id == ID.SETTING_EDITOR then
        filer:LoadFile(source .. sep .. "setting" .. sep .. "setting-editor.lua")
    elseif id == ID.SETTING_COMMAND then
        filer:LoadFile(source .. sep .. "setting" .. sep .. "setting-command.lua")
    end
end
