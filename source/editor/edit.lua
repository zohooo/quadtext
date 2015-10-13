-- ---------------------------------------------------------------------------
-- Create the Edit menu and attach the callback functions

local ID_CUT              = wx.wxID_CUT
local ID_COPY             = wx.wxID_COPY
local ID_PASTE            = wx.wxID_PASTE
local ID_SELECTALL        = wx.wxID_SELECTALL
local ID_UNDO             = wx.wxID_UNDO
local ID_REDO             = wx.wxID_REDO
local ID_AUTOCOMPLETE     = NewID()
local ID_AUTOCOMPLETE_ENABLE = NewID()
local ID_COMMENT          = NewID()
local ID_FOLD             = NewID()

editMenu = wx.wxMenu{
        { ID_CUT,       "Cu&t\tCtrl-X",        "Cut selected text to clipboard" },
        { ID_COPY,      "&Copy\tCtrl-C",       "Copy selected text to the clipboard" },
        { ID_PASTE,     "&Paste\tCtrl-V",      "Insert clipboard text at cursor" },
        { ID_SELECTALL, "Select A&ll\tCtrl-A", "Select all text in the editor" },
        { },
        { ID_UNDO,      "&Undo\tCtrl-Z",       "Undo the last action" },
        { ID_REDO,      "&Redo\tCtrl-Y",       "Redo the last action undone" },
        { },
        { ID_AUTOCOMPLETE,        "Complete &Identifier\tCtrl+K", "Complete the current identifier" },
        { ID_AUTOCOMPLETE_ENABLE, "Auto complete Identifiers",    "Auto complete while typing", wx.wxITEM_CHECK },
        { },
        { ID_COMMENT, "C&omment/Uncomment\tCtrl-Q", "Comment or uncomment current or selected lines"},
        { },
        { ID_FOLD,    "&Fold/Unfold all\tF12", "Fold or unfold all code folds"} }
menuBar:Append(editMenu, "&Edit")

editMenu:Check(ID_AUTOCOMPLETE_ENABLE, autoCompleteEnable)

toolBar:AddSeparator()
toolBar:AddTool(ID_CUT, "Cut",
                wx.wxArtProvider.GetBitmap(wx.wxART_CUT, wx.wxART_MENU, toolBmpSize),
                "Cut the selection")
toolBar:AddTool(ID_COPY, "Copy", 
                wx.wxArtProvider.GetBitmap(wx.wxART_COPY, wx.wxART_MENU, toolBmpSize),
                "Copy the selection")
toolBar:AddTool(ID_PASTE, "Paste",
                wx.wxArtProvider.GetBitmap(wx.wxART_PASTE, wx.wxART_MENU, toolBmpSize),
                "Paste text from the clipboard")
toolBar:AddSeparator()
toolBar:AddTool(ID_UNDO, "Undo",
                wx.wxArtProvider.GetBitmap(wx.wxART_UNDO, wx.wxART_MENU, toolBmpSize),
                "Undo last edit")
toolBar:AddTool(ID_REDO, "Redo",
                wx.wxArtProvider.GetBitmap(wx.wxART_REDO, wx.wxART_MENU, toolBmpSize),
                "Redo last undo")

function OnUpdateUIEditMenu(event) -- enable if there is a valid focused editor
    local editor = GetEditor()
    event:Enable(editor ~= nil)
end

function OnEditMenu(event)
    local menu_id = event:GetId()
    local editor = GetEditor()
    if editor == nil then return end

    if     menu_id == ID_CUT       then editor:Cut()
    elseif menu_id == ID_COPY      then editor:Copy()
    elseif menu_id == ID_PASTE     then editor:Paste()
    elseif menu_id == ID_SELECTALL then editor:SelectAll()
    elseif menu_id == ID_UNDO      then editor:Undo()
    elseif menu_id == ID_REDO      then editor:Redo()
    end
end

frame:Connect(ID_CUT, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_CUT, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_COPY, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_COPY, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_PASTE, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_PASTE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            -- buggy GTK clipboard runs eventloop and can generate asserts
            event:Enable(editor and (wx.__WXGTK__ or editor:CanPaste()))
        end)

frame:Connect(ID_SELECTALL, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_SELECTALL, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_UNDO, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_UNDO, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor and editor:CanUndo())
        end)

frame:Connect(ID_REDO, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_REDO, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor and editor:CanRedo())
        end)

frame:Connect(ID_AUTOCOMPLETE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            if (editor == nil) then return end
            local pos = editor:GetCurrentPos()
            local start_pos = editor:WordStartPosition(pos, true)
            -- must have "wx.XX" otherwise too many items
            if (pos - start_pos > 2) and (start_pos > 2) then
                local range = editor:GetTextRange(start_pos-3, start_pos)
                if range == "wx." then
                    local key = editor:GetTextRange(start_pos, pos)
                    local userList = CreateAutoCompList(key)
                    if userList and string.len(userList) > 0 then
                        editor:UserListShow(1, userList)
                    end
                end
            end
        end)
frame:Connect(ID_AUTOCOMPLETE, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_AUTOCOMPLETE_ENABLE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            autoCompleteEnable = event:IsChecked()
        end)

frame:Connect(ID_COMMENT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            local buf = {}
            if editor:GetSelectionStart() == editor:GetSelectionEnd() then
                local lineNumber = editor:GetCurrentLine()
                editor:SetSelection(editor:PositionFromLine(lineNumber), editor:GetLineEndPosition(lineNumber))
            end
            for line in string.gmatch(editor:GetSelectedText()..'\n', "(.-)\r?\n") do
                if string.sub(line,1,2) == '--' then
                    line = string.sub(line,3)
                else
                    line = '--'..line
                end
                table.insert(buf, line)
            end
            editor:ReplaceSelection(table.concat(buf,"\n"))
        end)
frame:Connect(ID_COMMENT, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

function FoldSome()
    local editor = GetEditor()
    editor:Colourise(0, -1)       -- update doc's folding info
    local visible, baseFound, expanded, folded
    for ln = 2, editor.LineCount - 1 do
        local foldRaw = editor:GetFoldLevel(ln)
        local foldLvl = math.mod(foldRaw, 4096)
        local foldHdr = math.mod(math.floor(foldRaw / 8192), 2) == 1
        if not baseFound and (foldLvl ==  wxstc.wxSTC_FOLDLEVELBASE) then
            baseFound = true
            visible = editor:GetLineVisible(ln)
        end
        if foldHdr then
            if editor:GetFoldExpanded(ln) then
                expanded = true
            else
                folded = true
            end
        end
        if expanded and folded and baseFound then break end
    end
    local show = not visible or (not baseFound and expanded) or (expanded and folded)
    local hide = visible and folded

    if show then
        editor:ShowLines(1, editor.LineCount-1)
    end

    for ln = 1, editor.LineCount - 1 do
        local foldRaw = editor:GetFoldLevel(ln)
        local foldLvl = math.mod(foldRaw, 4096)
        local foldHdr = math.mod(math.floor(foldRaw / 8192), 2) == 1
        if show then
            if foldHdr then
                if not editor:GetFoldExpanded(ln) then editor:ToggleFold(ln) end
            end
        elseif hide and (foldLvl == wxstc.wxSTC_FOLDLEVELBASE) then
            if not foldHdr then
                editor:HideLines(ln, ln)
            end
        elseif foldHdr then
            if editor:GetFoldExpanded(ln) then
                editor:ToggleFold(ln)
            end
        end
    end
    editor:EnsureCaretVisible()
end

frame:Connect(ID_FOLD, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            FoldSome()
        end)
frame:Connect(ID_FOLD, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)
