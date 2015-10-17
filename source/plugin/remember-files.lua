
local P = { name = "remember-files" }

P.onLoad = function()
    config:SetPath("/RememberFiles")
    local status, key, idx = config:GetFirstEntry("", 0)
    while status do
        local _, value = config:Read(key, "")
        if value ~= "" then
            LoadFile(value, editor, true)
        end
        status, key, idx = config:GetNextEntry(idx)
    end
    config:DeleteGroup("/RememberFiles")
end

P.onClose = function()
    for id, doc in pairs(openDocuments) do
        config:SetPath("/RememberFiles")
        print(doc.fullpath)
        config:Write(tostring(id), doc.fullpath)
    end
end

return P
