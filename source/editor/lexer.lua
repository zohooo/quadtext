
app.lexers = {}
app.filetype = {}

local all_lexers = {"tex", "lua"}

for _, name in ipairs(all_lexers) do
    local lexer = dofile(source .. "/lexer/lexer_" .. name .. ".lua")
    app.lexers[name] = lexer
    for _, ext in ipairs(lexer.extensions) do
        app.filetype[ext] = name
    end
end

function SetupKeywords(editor, ext)
    local name = app.filetype[ext]
    if name == nil then
        editor:SetLexer(wxstc.wxSTC_LEX_NULL)
        editor:SetKeyWords(0, "")
    else
        local lexer = app.lexers[name]
        editor:SetLexer(wxstc["wxSTC_LEX_" .. name:upper()])
        for k, v in ipairs(lexer.keywords) do
            editor:SetKeyWords(k-1, v)
        end
    end
    editor:Colourise(0, -1)
end
