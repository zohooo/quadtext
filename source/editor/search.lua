
findReplace = {
    dialog           = nil,   -- the wxDialog for find/replace
    replace          = false, -- is it a find or replace dialog
    fWholeWord       = false, -- match whole words
    fMatchCase       = false, -- case sensitive
    fDown            = true,  -- search downwards in doc
    fRegularExpr     = false, -- use regex
    fWrap            = false, -- search wraps around
    findTextArray    = {},    -- array of last entered find text
    findText         = "",    -- string to find
    replaceTextArray = {},    -- array of last entered replace text
    replaceText      = "",    -- string to replace find string with
    foundString      = false, -- was the string found for the last search

    -- HasText()                 is there a string to search for
    -- GetSelectedString()       get currently selected string if it's on one line
    -- FindString(reverse)       find the findText string
    -- Show(replace)             create the dialog
}

function EnsureRangeVisible(posStart, posEnd)
    local editor = GetEditor()
    if posStart > posEnd then
        posStart, posEnd = posEnd, posStart
    end

    local lineStart = editor:LineFromPosition(posStart)
    local lineEnd   = editor:LineFromPosition(posEnd)
    for line = lineStart, lineEnd do
        editor:EnsureVisibleEnforcePolicy(line)
    end
end

-------------------- Find replace dialog

function SetSearchFlags(editor)
    local flags = 0
    if findReplace.fWholeWord   then flags = wxstc.wxSTC_FIND_WHOLEWORD end
    if findReplace.fMatchCase   then flags = flags + wxstc.wxSTC_FIND_MATCHCASE end
    if findReplace.fRegularExpr then flags = flags + wxstc.wxSTC_FIND_REGEXP end
    editor:SetSearchFlags(flags)
end

function SetTarget(editor, fDown, fInclude)
    local selStart = editor:GetSelectionStart()
    local selEnd =  editor:GetSelectionEnd()
    local len = editor:GetLength()
    local s, e
    if fDown then
        e= len
        s = iff(fInclude, selStart, selEnd +1)
    else
        s = 0
        e = iff(fInclude, selEnd, selStart-1)
    end
    if not fDown and not fInclude then s, e = e, s end
    editor:SetTargetStart(s)
    editor:SetTargetEnd(e)
    return e
end

function findReplace:HasText()
    return (findReplace.findText ~= nil) and (string.len(findReplace.findText) > 0)
end

function findReplace:GetSelectedString()
    local editor = GetEditor()
    if editor then
        local startSel = editor:GetSelectionStart()
        local endSel   = editor:GetSelectionEnd()
        if (startSel ~= endSel) and (editor:LineFromPosition(startSel) == editor:LineFromPosition(endSel)) then
            findReplace.findText = editor:GetSelectedText()
            findReplace.foundString = true
        end
    end
end

function findReplace:FindString(reverse)
    if findReplace:HasText() then
        local editor = GetEditor()
        local fDown = iff(reverse, not findReplace.fDown, findReplace.fDown)
        local lenFind = string.len(findReplace.findText)
        SetSearchFlags(editor)
        SetTarget(editor, fDown)
        local posFind = editor:SearchInTarget(findReplace.findText)
        if (posFind == -1) and findReplace.fWrap then
            editor:SetTargetStart(iff(fDown, 0, editor:GetLength()))
            editor:SetTargetEnd(iff(fDown, editor:GetLength(), 0))
            posFind = editor:SearchInTarget(findReplace.findText)
        end
        if posFind == -1 then
            findReplace.foundString = false
            frame:SetStatusText("Find text not found.")
        else
            findReplace.foundString = true
            local start  = editor:GetTargetStart()
            local finish = editor:GetTargetEnd()
            EnsureRangeVisible(start, finish)
            editor:SetSelection(start, finish)
        end
    end
end

function ReplaceString(fReplaceAll)
    if findReplace:HasText() then
        local replaceLen = string.len(findReplace.replaceText)
        local editor = GetEditor()
        local findLen = string.len(findReplace.findText)
        local endTarget  = SetTarget(editor, findReplace.fDown, fReplaceAll)
        if fReplaceAll then
            SetSearchFlags(editor)
            local posFind = editor:SearchInTarget(findReplace.findText)
            if (posFind ~= -1)  then
                editor:BeginUndoAction()
                while posFind ~= -1 do
                    editor:ReplaceTarget(findReplace.replaceText)
                    editor:SetTargetStart(posFind + replaceLen)
                    endTarget = endTarget + replaceLen - findLen
                    editor:SetTargetEnd(endTarget)
                    posFind = editor:SearchInTarget(findReplace.findText)
                end
                editor:EndUndoAction()
            end
        else
            if findReplace.foundString then
                local start  = editor:GetSelectionStart()
                editor:ReplaceSelection(findReplace.replaceText)
                editor:SetSelection(start, start + replaceLen)
                findReplace.foundString = false
            end
            findReplace:FindString()
        end
    end
end

function CreateFindReplaceDialog(replace)
    local ID_FIND_NEXT   = 1
    local ID_REPLACE     = 2
    local ID_REPLACE_ALL = 3
    findReplace.replace  = replace

    local findDialog = wx.wxDialog(frame, wx.wxID_ANY, "Find",  wx.wxDefaultPosition, wx.wxDefaultSize)

    -- Create right hand buttons and sizer
    local findButton = wx.wxButton(findDialog, ID_FIND_NEXT, "&Find Next")
    findButton:SetDefault()
    local replaceButton =  wx.wxButton(findDialog, ID_REPLACE, "&Replace")
    local replaceAllButton = nil
    if (replace) then
        replaceAllButton =  wx.wxButton(findDialog, ID_REPLACE_ALL, "Replace &All")
    end
    local cancelButton =  wx.wxButton(findDialog, wx.wxID_CANCEL, "Cancel")

    local buttonsSizer = wx.wxBoxSizer(wx.wxVERTICAL)
    buttonsSizer:Add(findButton,    0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    buttonsSizer:Add(replaceButton, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    if replace then
        buttonsSizer:Add(replaceAllButton, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    end
    buttonsSizer:Add(cancelButton, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER,  3)

    -- Create find/replace text entry sizer
    local findStatText  = wx.wxStaticText( findDialog, wx.wxID_ANY, "Find: ")
    local findTextCombo = wx.wxComboBox(findDialog, wx.wxID_ANY, findReplace.findText,  wx.wxDefaultPosition, wx.wxDefaultSize, findReplace.findTextArray, wx.wxCB_DROPDOWN)
    findTextCombo:SetFocus()

    local replaceStatText, replaceTextCombo
    if (replace) then
        replaceStatText  = wx.wxStaticText( findDialog, wx.wxID_ANY, "Replace: ")
        replaceTextCombo = wx.wxComboBox(findDialog, wx.wxID_ANY, findReplace.replaceText,  wx.wxDefaultPosition, wx.wxDefaultSize,  findReplace.replaceTextArray)
    end

    local findReplaceSizer = wx.wxFlexGridSizer(2, 2, 0, 0)
    findReplaceSizer:AddGrowableCol(1)
    findReplaceSizer:Add(findStatText,  0, wx.wxALL + wx.wxALIGN_LEFT, 0)
    findReplaceSizer:Add(findTextCombo, 1, wx.wxALL + wx.wxGROW + wx.wxCENTER, 0)

    if (replace) then
        findReplaceSizer:Add(replaceStatText,  0, wx.wxTOP + wx.wxALIGN_CENTER, 5)
        findReplaceSizer:Add(replaceTextCombo, 1, wx.wxTOP + wx.wxGROW + wx.wxCENTER, 5)
    end

    -- Create the static box sizer before adding items to it.
    local optionsSizer = wx.wxStaticBoxSizer(wx.wxVERTICAL, findDialog, "Options" );
    local optionSizer = wx.wxBoxSizer(wx.wxVERTICAL, findDialog)

    -- Create find/replace option checkboxes
    local wholeWordCheckBox  = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Match &whole word")
    local matchCaseCheckBox  = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Match &case")
    local wrapAroundCheckBox = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Wrap ar&ound")
    local regexCheckBox      = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Regular &expression")
    wholeWordCheckBox:SetValue(findReplace.fWholeWord)
    matchCaseCheckBox:SetValue(findReplace.fMatchCase)
    wrapAroundCheckBox:SetValue(findReplace.fWrap)
    regexCheckBox:SetValue(findReplace.fRegularExpr)

    optionSizer:Add(wholeWordCheckBox,  0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    optionSizer:Add(matchCaseCheckBox,  0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    optionSizer:Add(wrapAroundCheckBox, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    optionSizer:Add(regexCheckBox,      0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    optionsSizer:Add(optionSizer, 0, 0, 5)

    -- Create scope radiobox
    local scopeRadioBox = wx.wxRadioBox(findDialog, wx.wxID_ANY, "Scope", wx.wxDefaultPosition, wx.wxDefaultSize,  {"&Up", "&Down"}, 1, wx.wxRA_SPECIFY_COLS)
    scopeRadioBox:SetSelection(iff(findReplace.fDown, 1, 0))
    local scopeSizer = wx.wxBoxSizer(wx.wxVERTICAL, findDialog );
    scopeSizer:Add(scopeRadioBox, 0, 0, 0)

    -- Add all the sizers to the dialog
    local optionScopeSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    optionScopeSizer:Add(optionsSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)
    optionScopeSizer:Add(scopeSizer,   0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)

    local leftSizer = wx.wxBoxSizer(wx.wxVERTICAL)
    leftSizer:Add(findReplaceSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 0)
    leftSizer:Add(optionScopeSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 0)

    local mainSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    mainSizer:Add(leftSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 10)
    mainSizer:Add(buttonsSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 10)
    mainSizer:SetSizeHints( findDialog )
    findDialog:SetSizer(mainSizer)

    local function PrependToArray(t, s)
        if string.len(s) == 0 then return end
        for i, v in ipairs(t) do
            if v == s then
                table.remove(t, i) -- remove old copy
                break
            end
        end
        table.insert(t, 1, s)
        if #t > 15 then table.remove(t, #t) end -- keep reasonable length
    end

    local function TransferDataFromWindow()
        findReplace.fWholeWord   = wholeWordCheckBox:GetValue()
        findReplace.fMatchCase   = matchCaseCheckBox:GetValue()
        findReplace.fWrap        = wrapAroundCheckBox:GetValue()
        findReplace.fDown        = scopeRadioBox:GetSelection() == 1
        findReplace.fRegularExpr = regexCheckBox:GetValue()
        findReplace.findText     = findTextCombo:GetValue()
        PrependToArray(findReplace.findTextArray, findReplace.findText)
        if findReplace.replace then
            findReplace.replaceText = replaceTextCombo:GetValue()
            PrependToArray(findReplace.replaceTextArray, findReplace.replaceText)
        end
        return true
    end

    findDialog:Connect(ID_FIND_NEXT, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function(event)
            TransferDataFromWindow()
            findReplace:FindString()
        end)

    findDialog:Connect(ID_REPLACE, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function(event)
            TransferDataFromWindow()
            event:Skip()
            if findReplace.replace then
                ReplaceString()
            else
                findReplace.dialog:Destroy()
                findReplace.dialog = CreateFindReplaceDialog(true)
                findReplace.dialog:Show(true)
            end
        end)

    if replace then
        findDialog:Connect(ID_REPLACE_ALL, wx.wxEVT_COMMAND_BUTTON_CLICKED,
            function(event)
                TransferDataFromWindow()
                event:Skip()
                ReplaceString(true)
            end)
    end

    findDialog:Connect(wx.wxID_ANY, wx.wxEVT_CLOSE_WINDOW,
        function (event)
            TransferDataFromWindow()
            event:Skip()
            findDialog:Show(false)
            findDialog:Destroy()
        end)

    return findDialog
end

function findReplace:Show(replace)
    self.dialog = nil
    self.dialog = CreateFindReplaceDialog(replace)
    self.dialog:Show(true)
end
