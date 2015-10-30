
local editorID = 100 -- window id to create editor pages with, incremented for new editors

local myEditor = {} -- extending the editor class

function myEditor:SwitchComment()
    local editor = self
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
end

function myEditor:SwitchFold()
    local editor = self
    editor:Colourise(0, -1)       -- update doc's folding info
    local visible, baseFound, expanded, folded
    for ln = 2, editor.LineCount - 1 do
        local foldRaw = editor:GetFoldLevel(ln)
        local foldLvl = foldRaw % 4096
        local foldHdr = (math.floor(foldRaw / 8192) % 2) == 1
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
        local foldLvl = foldRaw % 4096
        local foldHdr = (math.floor(foldRaw / 8192) % 2) == 1
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

function app:CreateEditor(parent, ...)
    local editor = wxstc.wxStyledTextCtrl(parent, editorID, ...)
    editorID = editorID + 1 -- increment so they're always unique

    -- We could not write the following line, since editor is not a table
    -- setmetatable(editor, {__index = myEditor})
    editor.SwitchComment = myEditor.SwitchComment
    editor.SwitchFold = myEditor.SwitchFold

    editor:SetBufferedDraw(true)
    editor:StyleClearAll()

    editor:SetFont(font)
    editor:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, font)
    for i = 0, 32 do
        editor:StyleSetFont(i, font)
    end

    editor:SetUseTabs(false)
    editor:SetTabWidth(4)
    editor:SetIndent(4)
    editor:SetIndentationGuides(true)

    local wrapmode = app.setting.editor.wrapmode or 1
    editor:SetWrapMode(tonumber(wrapmode))

    editor:SetVisiblePolicy(wxstc.wxSTC_VISIBLE_SLOP, 3)
    --editor:SetXCaretPolicy(wxstc.wxSTC_CARET_SLOP, 10)
    --editor:SetYCaretPolicy(wxstc.wxSTC_CARET_SLOP, 3)

    editor:SetCaretLineVisible(true)
    editor:SetCaretLineBackground(wx.wxColour(244, 244, 222))

    editor:SetMarginWidth(0, editor:TextWidth(32, "99999_")) -- line # margin

    editor:SetMarginWidth(1, 16) -- marker margin
    editor:SetMarginType(1, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginSensitive(1, true)

    editor:MarkerDefine(CURRENT_LINE_MARKER, wxstc.wxSTC_MARK_ARROW,     wx.wxBLACK, wx.wxGREEN)

    editor:SetMarginWidth(2, 16) -- fold margin
    editor:SetMarginType(2, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginMask(2, wxstc.wxSTC_MASK_FOLDERS)
    editor:SetMarginSensitive(2, true)

    editor:SetFoldFlags(wxstc.wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED +
                        wxstc.wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED)

    editor:SetProperty("fold", "1")
    editor:SetProperty("fold.compact", "1")
    editor:SetProperty("fold.comment", "1")

    local grey = wx.wxColour(128, 128, 128)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEROPEN,    wxstc.wxSTC_MARK_BOXMINUS, wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDER,        wxstc.wxSTC_MARK_BOXPLUS,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERSUB,     wxstc.wxSTC_MARK_VLINE,    wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERTAIL,    wxstc.wxSTC_MARK_LCORNER,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEREND,     wxstc.wxSTC_MARK_BOXPLUSCONNECTED,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEROPENMID, wxstc.wxSTC_MARK_BOXMINUSCONNECTED, wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERMIDTAIL, wxstc.wxSTC_MARK_TCORNER,  wx.wxWHITE, grey)
    grey:delete()

    editor:Connect(wxstc.wxEVT_STC_MARGINCLICK,
            function (event)
                local line = editor:LineFromPosition(event:GetPosition())
                local margin = event:GetMargin()
                if margin == 2 then
                    if wx.wxGetKeyState(wx.WXK_SHIFT) and wx.wxGetKeyState(wx.WXK_CONTROL) then
                        FoldSome()
                    else
                        local level = editor:GetFoldLevel(line)
                        if HasBit(level, wxstc.wxSTC_FOLDLEVELHEADERFLAG) then
                            editor:ToggleFold(line)
                        end
                    end
                end
            end)

    editor:Connect(wxstc.wxEVT_STC_CHARADDED,
            function (event)
                -- auto-indent
                local ch = event:GetKey()
                if (ch == char_CR) or (ch == char_LF) then
                    local pos = editor:GetCurrentPos()
                    local line = editor:LineFromPosition(pos)

                    if (line > 0) and (editor:LineLength(line) == 0) then
                        local indent = editor:GetLineIndentation(line - 1)
                        if indent > 0 then
                            editor:SetLineIndentation(line, indent)
                            editor:GotoPos(pos + indent)
                        end
                    end
                elseif autoCompleteEnable then -- code completion prompt
                    local pos = editor:GetCurrentPos()
                    local start_pos = editor:WordStartPosition(pos, true)
                    -- must have "wx.X" otherwise too many items
                    if (pos - start_pos > 0) and (start_pos > 2) then
                        local range = editor:GetTextRange(start_pos-3, start_pos)
                        if range == "wx." then
                            local commandEvent = wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED,
                                                                   ID.AUTOCOMPLETE)
                            wx.wxPostEvent(frame, commandEvent)
                        end
                    end
                end
            end)

    editor:Connect(wxstc.wxEVT_STC_USERLISTSELECTION,
            function (event)
                local pos = editor:GetCurrentPos()
                local start_pos = editor:WordStartPosition(pos, true)
                editor:SetSelection(start_pos, pos)
                editor:ReplaceSelection(event:GetText())
            end)

    editor:Connect(wxstc.wxEVT_STC_SAVEPOINTREACHED,
            function (event)
                SetDocumentModified(editor:GetId(), false)
            end)

    editor:Connect(wxstc.wxEVT_STC_SAVEPOINTLEFT,
            function (event)
                SetDocumentModified(editor:GetId(), true)
            end)

    editor:Connect(wxstc.wxEVT_STC_UPDATEUI,
            function (event)
                UpdateStatusText(editor)
            end)

    editor:Connect(wx.wxEVT_SET_FOCUS,
            function (event)
                event:Skip()
                if in_evt_focus or exitingProgram then return end
                in_evt_focus = true
                IsFileAlteredOnDisk(editor)
                in_evt_focus = false
            end)

    return editor
end
