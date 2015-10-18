-- ---------------------------------------------------------------------------
-- Create the Option menu and attach the callback functions

local ID_SETTING_EDITOR  = NewID()
local ID_SETTING_COMMAND = NewID()

optionMenu = wx.wxMenu{
    { ID_SETTING_EDITOR, "Setting &Editor", "Setting Editor" },
    { ID_SETTING_COMMAND, "Setting &Commands", "Setting Commands" },
}
menuBar:Append(optionMenu, "&Option")

function OpenSettingFile(event)
    local id = event:GetId()
    if id == ID_SETTING_EDITOR then
        LoadFile(source .. sep .. "setting" .. sep .. "setting-editor.lua")
    elseif id == ID_SETTING_COMMAND then
        LoadFile(source .. sep .. "setting" .. sep .. "setting-command.lua")
    end
end

frame:Connect(ID_SETTING_EDITOR, wx.wxEVT_COMMAND_MENU_SELECTED, OpenSettingFile)
frame:Connect(ID_SETTING_COMMAND, wx.wxEVT_COMMAND_MENU_SELECTED, OpenSettingFile)
