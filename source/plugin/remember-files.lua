
local P = { name = "remember-files" }

P.onLoad = function()
    local config = app:GetConfig()
    if not config then return end
    config:SetPath("/RememberFiles")
    local status, key, idx = config:GetFirstEntry("", 0)
    while status do
        local _, value = config:Read(key, "")
        if value ~= "" then
            filer:LoadFile(value, nil, true)
        end
        status, key, idx = config:GetNextEntry(idx)
    end
    config:DeleteGroup("/RememberFiles")
    config:delete() -- the changes will be written back automatically
end

P.onClose = function()
    local config = app:GetConfig()
    if not config then return end
    for id, doc in pairs(notebook.openDocuments) do
        -- exclude untitled files
        if doc.fullpath then
            config:SetPath("/RememberFiles")
            config:Write(tostring(id), doc.fullpath)
        end
    end
    config:delete() -- the changes will be written back automatically
end

return P
