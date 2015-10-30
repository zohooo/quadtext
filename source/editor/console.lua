
console = wxstc.wxStyledTextCtrl(splitter, wx.wxID_ANY)

console:Show(false)
console:SetFont(font)
console:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, font)
console:StyleClearAll()

console:SetMarginWidth(1, 16) -- marker margin
console:SetMarginType(1, wxstc.wxSTC_MARGIN_SYMBOL);
console:MarkerDefine(CURRENT_LINE_MARKER, wxstc.wxSTC_MARK_ARROWS, wx.wxBLACK, wx.wxWHITE)

console:SetReadOnly(true)

local consoleLength = 0

function console:DisplayOutput(message, dont_add_marker)
    if splitter:IsSplit() == false then
        local w, h = frame:GetClientSizeWH()
        splitter:SplitHorizontally(notebook, console, (2 * h) / 3)
    end
    if not dont_add_marker then
        console:MarkerAdd(console:GetLineCount()-1, CURRENT_LINE_MARKER)
    end
    console:SetReadOnly(false)
    console:AppendText(message)
    console:SetReadOnly(true)
    local n = console:GetLength()
    console:GotoPos(n)
    consoleLength = n
end

function console:ClearOutput()
    console:SetReadOnly(false)
    console:ClearAll()
    console:SetReadOnly(true)
end

local proc, streamOut, streamErr, streamIn

local function ReadStream()
    local function doRead(stream)
        if stream and stream:CanRead() then
            local str = stream:Read(4096)
            console:DisplayOutput(str)
        else
            console:SetReadOnly(false)
        end
    end
    doRead(streamIn)
    doRead(streamErr)
end

local function WriteStream(s)
    if streamOut then streamOut:Write(s, #s) end
end

local execTimer = wx.wxTimer(console, ID.TIMER_EXECUTION)

function console:ExecCommand(cmd, dir)
    proc = wx.wxProcess()
    proc:Redirect()
    proc:Connect(wx.wxEVT_END_PROCESS,
        function(event)
            execTimer:Stop();
            ReadStream()
            proc = nil
        end)

    if menuBar:IsChecked(ID.CLEAROUTPUT) then
        console:ClearOutput()
        consoleLength = 0
    end
    console:DisplayOutput("Running program: "..cmd.."\n")
    local cwd = wx.wxGetCwd()
    wx.wxSetWorkingDirectory(dir)
    local pid = wx.wxExecute(cmd, wx.wxEXEC_ASYNC, proc)
    wx.wxSetWorkingDirectory(cwd)

    if pid == -1 then
        console:DisplayOutput("Unknown ERROR Running program!\n", true)
    else
        streamIn = proc and proc:GetInputStream()
        streamErr = proc and proc:GetErrorStream()
        streamOut = proc and proc:GetOutputStream()
        execTimer:Start(200);
    end
end

console:Connect(ID.TIMER_EXECUTION, wx.wxEVT_TIMER, ReadStream)

console:Connect(wx.wxEVT_KEY_DOWN,
    function (event)
        local key = event:GetKeyCode()
        if key == wx.WXK_RETURN or key == wx.WXK_NUMPAD_ENTER then
            local n = console:GetLength()
            local s = console:GetTextRange(consoleLength, n)
            WriteStream(s .. "\n")
        end
        event:Skip()
    end)
