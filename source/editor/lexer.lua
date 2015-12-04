
app.lexers = {}
app.filetype = {}

local all_lexers = {"tex", "lua"}

for _, name in ipairs(all_lexers) do
    local lexer = dofile(app:GetPath("source", "lexer", "lexer_" .. name .. ".lua"))
    app.lexers[name] = lexer
    for _, ext in ipairs(lexer.extensions) do
        app.filetype[ext] = name
    end
end

local function DoSetupKeywords(editor, name)
    if name == nil then
        editor:SetLexer(wxstc.wxSTC_LEX_NULL)
        editor:SetKeyWords(0, "")
    else
        local lexer = app.lexers[name]
        editor:SetLexer(wxstc["wxSTC_LEX_" .. name:upper()])
        for k, v in ipairs(lexer.keywords) do
            editor:SetKeyWords(k-1, v)
        end
        -- for auto completion
        local wordlist = table.concat(lexer.keywords, " ")
        local prefix = lexer.keywordPrefix or ""
        wordlist = " " .. string.gsub(wordlist, "%s+", " ")
        editor:UpdateKeywords(wordlist, prefix)
    end
end

local function DoSetupStyles(editor, n, style)
    for k, v in pairs(style) do
        if k == "fg" then
            editor:StyleSetForeground(n, wx.wxColour(v[1], v[2], v[3]))
        elseif k == "bg" then
            editor:StyleSetBackground(n, wx.wxColour(v[1], v[2], v[3]))
        elseif k == "bold" then
            editor:StyleSetBold(n,v)
        elseif k == "fill" then
            editor:StyleSetEOLFilled(n, v)
        end
    end
end

function notebook:SetupEditor(editor, ext)
    local name = app.filetype[ext]
    if name ~= nil then
        local lexer = app.lexers[name]
        for key, style in pairs(app.theme.styles.common) do
            local n = wxstc["wxSTC_STYLE_" .. key:upper()]
            DoSetupStyles(editor, n, style)
        end
        for key, style in pairs(app.theme.styles[name]) do
            local n = wxstc["wxSTC_" .. name:upper() .. "_" .. key:upper()]
            DoSetupStyles(editor, n, style)
        end
        editor.lexer = lexer
    end
    DoSetupKeywords(editor, name)
    editor:Colourise(0, -1)
end
