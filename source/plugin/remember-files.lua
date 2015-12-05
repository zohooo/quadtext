
local P = { name = "remember-files" }

P.onLoad = function()
    local config = app:GetConfig()
    if not config then return end
    config:SetPath("/RememberFiles")
    local status, key, idx = config:GetFirstEntry("", 0)
    while status do
        local _, value = config:Read(key, "")
        if value ~= "" then
            local i, _ = string.find(value, "|")
            if i then
                local enc = string.sub(value, 1, i-1)
                local path = string.sub(value, i+1)
                filer:LoadFile(path, nil, true, enc)
            end
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
            config:Write(tostring(id), doc.encoding .. "|" .. doc.fullpath)
        end
    end
    config:delete() -- the changes will be written back automatically
end

return P
