
menubar = wx.wxMenuBar()

-- ---------------------------------------------------------------------------
-- Create the File menu

local fileMenu = wx.wxMenu({
        { ID.NEW,     "&New\tCtrl-N",        "Create an empty document" },
        { ID.OPEN,    "&Open...\tCtrl-O",    "Open an existing document" },
        { ID.CLOSE,   "&Close page\tCtrl+W", "Close the current editor window" },
        { },
        { ID.SAVE,    "&Save\tCtrl-S",       "Save the current document" },
        { ID.SAVEAS,  "Save &As...\tAlt-S",  "Save the current document to a file with a new name" },
        { ID.SAVEALL, "Save A&ll...\tCtrl-Shift-S", "Save all open documents" },
        { },
        { ID.PRINT,         "&Print... \tCtrl-P",               "Print document"},
        { ID.PRINT_PREVIEW, "&Print Preview... \tShift-Ctrl-P", "Print preview"},
        { ID.PAGE_SETUP,    "Page S&etup...",                   "Set up printing"},
        { },
        { ID.EXIT,    "E&xit\tAlt-X",        "Exit Program" }})
menubar:Append(fileMenu, "&File")

-- ---------------------------------------------------------------------------
-- Create the Edit menu

local editMenu = wx.wxMenu{
        { ID.CUT,       "Cu&t\tCtrl-X",        "Cut selected text to clipboard" },
        { ID.COPY,      "&Copy\tCtrl-C",       "Copy selected text to the clipboard" },
        { ID.PASTE,     "&Paste\tCtrl-V",      "Insert clipboard text at cursor" },
        { ID.SELECTALL, "Select A&ll\tCtrl-A", "Select all text in the editor" },
        { },
        { ID.UNDO,      "&Undo\tCtrl-Z",       "Undo the last action" },
        { ID.REDO,      "&Redo\tCtrl-Y",       "Redo the last action undone" },
        { },
        { ID.AUTOCOMPLETE,        "Complete &Identifier\tCtrl+K", "Complete the current identifier" },
        { ID.AUTOCOMPLETE_ENABLE, "Auto complete Identifiers",    "Auto complete while typing", wx.wxITEM_CHECK },
        { },
        { ID.COMMENT, "C&omment/Uncomment\tCtrl-Q", "Comment or uncomment current or selected lines"},
        { },
        { ID.FOLD,    "&Fold/Unfold all\tF12", "Fold or unfold all code folds"} }
menubar:Append(editMenu, "&Edit")

editMenu:Check(ID.AUTOCOMPLETE_ENABLE, autoCompleteEnable)

-- ---------------------------------------------------------------------------
-- Create the Search menu

local findMenu = wx.wxMenu{
        { ID.FIND,       "&Find\tCtrl-F",            "Find the specified text" },
        { ID.FINDNEXT,   "Find &Next\tF3",           "Find the next occurrence of the specified text" },
        { ID.FINDPREV,   "Find &Previous\tShift-F3", "Repeat the search backwards in the file" },
        { ID.REPLACE,    "&Replace\tCtrl-H",         "Replaces the specified text with different text" },
        { },
        { ID.GOTOLINE,   "&Goto line\tCtrl-G",       "Go to a selected line" },
        { },
        { ID.SORT,       "&Sort",                    "Sort selected lines"}}
menubar:Append(findMenu, "&Search")

-- ---------------------------------------------------------------------------
-- Create the Tool menu

local toolMenu = wx.wxMenu{
        { ID.COMPILE,          "&Compile\tF5",          "Compile current file" },
        { ID.PREVIEW,          "&Preview\tF6",          "Preview output file" },
        { },
        { ID.SHOWHIDEWINDOW,   "View &Output Window\tF8", "View or Hide the output window", wx.wxITEM_CHECK },
        { ID.CLEAROUTPUT,      "C&lear Output Window",    "Clear the output window"},
        }
menubar:Append(toolMenu, "&Tool")

-- ---------------------------------------------------------------------------
-- Create the Option menu

local optionMenu = wx.wxMenu{
    { ID.SETTING_EDITOR, "Setting &Editor", "Setting Editor" },
    { ID.SETTING_COMMAND, "Setting &Commands", "Setting Commands" },
}
menubar:Append(optionMenu, "&Option")

-- ---------------------------------------------------------------------------
-- Create the Help menu

local helpMenu = wx.wxMenu{
    { ID.ABOUT,        "&About\tF1", "About QuadText" },
    { ID.HELP_PROJECT, "&Project Page", "Open Project Page" },
    { ID.HELP_SUPPORT, "&Support", "Open Project Wiki" },
}
menubar:Append(helpMenu, "&Help")

-- ---------------------------------------------------------------------------
-- Add menubar to main frame

frame:SetMenuBar(menubar)
