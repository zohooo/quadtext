
local lexer = {extensions = {"tex", "sty", "cls"}, styles = {}, keywords = {}}

lexer.keywordPrefix = "\\"

-- http://www.scintilla.org/ScintillaDoc.html#StyleDefinition
lexer.styles.common = {
    default     = {fg = {224, 192, 224}},
    linenumber  = {fg = {  0,   0,   0}, bg = {192, 192, 192}},
    bracelight  = {fg = {  0,   0, 255}, bold = true},
    bracebad    = {fg = {255,   0,   0}, bold = true},
    controlchar = {fg = {128, 128, 128}},
    indentguide = {fg = {192, 192, 192}, bg = {255, 255, 255}},
    calltip     = {fg = {128, 128, 128}},
}

-- http://sourceforge.net/p/scintilla/code/ci/default/tree/include/SciLexer.h
lexer.styles.current = {
    default = {fg = {128, 128, 128}}, -- comments
    special = {fg = {  0, 128,   0}}, -- [ ] () <> # = "
    group   = {fg = {  0, 128,   0}}, -- { } $
    symbol  = {fg = { 64,  64,  64}}, -- % & ^ _ + - / | ~ `
    command = {fg = {  0, 128, 128}}, -- commands
    text    = {fg = {  0,   0,   0}}, -- text
}

lexer.keywords[1] = [[
    alpha active appendix approx arabic arccos arcsin arctan
    bar begin beta big bigcap bigcup bigskip boldmath bullet
    catcode cdot cdots centering cfrac chapter chi circ cite color cos
    Delta date ddot ddots delta dfrac displaystyle documentclass dotfill
    egroup eject end enskip epsilon equal eta
    fbox font footline forall frac frame frametitle
    Gamma gamma gcd ge geq grave
    hat hbox height hfill hline
    iint in includegraphics indent infty input int iota item
    jobname kappa kern kill
    Lambda lambda large le left leq lim limits
    magstep markboth markright mathrm mbox middle mu
    nabla newif newpage nmid nu
    Omega omega onslide outer overline overset
    Phi Pi Psi paragraph part pause phi pi psi
    quad qquad
    rho right rlap rmfamily rule
    section setcounter sigma sim sin subsection subsubsection sum
    Theta tau text textbf textwidth theta times title titlepage to
    Upsilon underline unskip upsilon usepackage
    vadjust value varphi varpi varrho vfill
    warning widehat width wlog write
    Xi xdef xi year zeta
]]

return lexer
