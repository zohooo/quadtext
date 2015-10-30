-- ---------------------------------------------------------------------------
-- Create the Option menu and attach the callback functions

optionMenu = wx.wxMenu{
    { ID.SETTING_EDITOR, "Setting &Editor", "Setting Editor" },
    { ID.SETTING_COMMAND, "Setting &Commands", "Setting Commands" },
}
menuBar:Append(optionMenu, "&Option")

function OpenSettingFile(event)
    local id = event:GetId()
    if id == ID.SETTING_EDITOR then
        LoadFile(source .. sep .. "setting" .. sep .. "setting-editor.lua")
    elseif id == ID.SETTING_COMMAND then
        LoadFile(source .. sep .. "setting" .. sep .. "setting-command.lua")
    end
end

frame:Connect(ID.SETTING_EDITOR, wx.wxEVT_COMMAND_MENU_SELECTED, OpenSettingFile)
frame:Connect(ID.SETTING_COMMAND, wx.wxEVT_COMMAND_MENU_SELECTED, OpenSettingFile)
