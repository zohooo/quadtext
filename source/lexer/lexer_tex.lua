
local lexer = {
    extensions = {"tex", "sty", "cls"},
    comment = "%",
    keywords = {},
    keywordPrefix = "\\",
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
