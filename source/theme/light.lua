
local theme = {styles = {}}

-- http://www.scintilla.org/ScintillaDoc.html#StyleDefinition
-- http://sourceforge.net/p/scintilla/code/ci/default/tree/include/SciLexer.h

theme.styles.common = {
    default     = {fg = {224, 192, 224}},
    linenumber  = {fg = {  0,   0,   0}, bg = {192, 192, 192}},
    bracelight  = {fg = {  0,   0, 255}, bold = true},
    bracebad    = {fg = {255,   0,   0}, bold = true},
    controlchar = {fg = {128, 128, 128}},
    indentguide = {fg = {192, 192, 192}, bg = {255, 255, 255}},
    calltip     = {fg = {128, 128, 128}},
}


theme.styles.tex = {
    default = {fg = {128, 128, 128}}, -- comments
    special = {fg = {  0, 128,   0}}, -- [ ] () <> # = "
    group   = {fg = {  0, 128,   0}}, -- { } $
    symbol  = {fg = { 64,  64,  64}}, -- % & ^ _ + - / | ~ `
    command = {fg = {  0, 128, 128}}, -- commands
    text    = {fg = {  0,   0,   0}}, -- text
}

theme.styles.lua = {
    default       = {fg = {127, 127, 127}},
    comment       = {fg = {  0, 127,   0}},
    commentline   = {fg = {  0, 127,   0}},
    commentdoc    = {fg = {127, 127, 127}},
    number        = {fg = {  0, 127, 127}},
    word          = {fg = {  0,   0, 127}, bold = true},
    string        = {fg = {127,   0, 127}},
    character     = {fg = {127,   0, 127}},
    literalstring = {fg = {  0, 127, 127}},
    preprocessor  = {fg = {127, 127,   0}},
    operator      = {fg = {  0,   0,   0}, bold = true},
    identifier    = {fg = {  0,   0,   0}},
    stringeol     = {fg = {  0,   0,   0}, bg = {224, 192, 224}, bold=true, fill=true},
    word2         = {fg = {  0,   0,  95}},
    word3         = {fg = {  0,  95,   0}},
    word4         = {fg = {127,   0,   0}},
    word5         = {fg = {127,   0,  95}},
    word6         = {fg = { 35,  95, 175}},
    word7         = {fg = {  0, 127, 127}},
    word8         = {fg = {  0,   0,   0}, bg = {240, 255, 255}},
}

return theme
