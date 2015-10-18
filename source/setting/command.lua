
app.setting.command = {
    compile = [[xelatex -synctex=1 "#fullname"]],
    preview = [[SumatraPDF -inverse-search "#program -line=%l \"%f\"" "#basename.pdf"]],
}
