
local theme = {styles = {}}

-- http://www.scintilla.org/ScintillaDoc.html#StyleDefinition
-- http://sourceforge.net/p/scintilla/code/ci/default/tree/include/SciLexer.h

theme.styles.common = {
    default     = {fg = {224, 192, 224}, bg = { 64,  64,  64}},
    linenumber  = {fg = {  0,   0,   0}, bg = {192, 192, 192}},
    bracelight  = {fg = {  0,   0, 255}, bold = true},
    bracebad    = {fg = {255,   0,   0}, bold = true},
    controlchar = {fg = {128, 128, 128}},
    indentguide = {fg = {192, 192, 192}, bg = {255, 255, 255}},
    calltip     = {fg = {128, 128, 128}},
}


theme.styles.tex = {
    default = {fg = {128, 128, 128}, bg = { 64,  64,  64}}, -- comments
    special = {fg = {  0, 128,   0}, bg = { 64,  64,  64}}, -- [ ] () <> # = "
    group   = {fg = {  0, 128,   0}, bg = { 64,  64,  64}}, -- { } $
    symbol  = {fg = {192, 192, 192}, bg = { 64,  64,  64}}, -- % & ^ _ + - / | ~ `
    command = {fg = {  0, 128, 128}, bg = { 64,  64,  64}}, -- commands
    text    = {fg = {192, 192, 192}, bg = { 64,  64,  64}}, -- text
}

theme.styles.lua = {
    default       = {fg = {192, 192, 192}, bg = { 64,  64,  64}},
    comment       = {fg = {  0, 127,   0}, bg = { 64,  64,  64}},
    commentline   = {fg = {  0, 127,   0}, bg = { 64,  64,  64}},
    commentdoc    = {fg = {127, 127, 127}, bg = { 64,  64,  64}},
    number        = {fg = {  0, 127, 127}, bg = { 64,  64,  64}},
    word          = {fg = { 16,  16, 112}, bg = { 64,  64,  64}, bold = true},
    string        = {fg = {127,   0, 127}, bg = { 64,  64,  64}},
    character     = {fg = {127,   0, 127}, bg = { 64,  64,  64}},
    literalstring = {fg = {  0, 127, 127}, bg = { 64,  64,  64}},
    preprocessor  = {fg = {127, 127,   0}, bg = { 64,  64,  64}},
    operator      = {fg = {192, 192, 192}, bg = { 64,  64,  64}, bold = true},
    identifier    = {fg = {192, 192, 192}, bg = { 64,  64,  64}},
    stringeol     = {fg = {192, 192, 192}, bg = {224, 192, 224}, bold = true, fill = true},
    word2         = {fg = {  0,   0,  95}, bg = { 64,  64,  64}},
    word3         = {fg = {  0,  95,   0}, bg = { 64,  64,  64}},
    word4         = {fg = {192,  64,  64}, bg = { 64,  64,  64}},
    word5         = {fg = {127,   0,  95}, bg = { 64,  64,  64}},
    word6         = {fg = { 35,  95, 175}, bg = { 64,  64,  64}},
    word7         = {fg = {  0, 127, 127}, bg = { 64,  64,  64}},
    word8         = {fg = {192, 192, 192}, bg = {240, 255, 255}},
}

return theme
