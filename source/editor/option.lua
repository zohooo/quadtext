
function OpenSettingFile(event)
    local id = event:GetId()
    if id == ID.SETTING_EDITOR then
        filer:LoadFile(source .. sep .. "setting" .. sep .. "setting-editor.lua")
    elseif id == ID.SETTING_COMMAND then
        filer:LoadFile(source .. sep .. "setting" .. sep .. "setting-command.lua")
    end
end

frame:Connect(ID.SETTING_EDITOR, wx.wxEVT_COMMAND_MENU_SELECTED, OpenSettingFile)
frame:Connect(ID.SETTING_COMMAND, wx.wxEVT_COMMAND_MENU_SELECTED, OpenSettingFile)
