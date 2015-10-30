
dofile(source .. sep .. "setting" .. sep .. "setting-command.lua")

function SetAllEditorsReadOnly(enable)
    for id, document in pairs(openDocuments) do
        local editor = document.editor
        editor:SetReadOnly(enable)
    end
end

function MakeFileName(editor, fullpath)
    if not fullpath then
        fullpath = "file"..tostring(editor)
    end
    return fullpath
end

local consoleLength = 0

function DisplayOutput(message, dont_add_marker)
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

function SaveIfModified(editor)
    local id = editor:GetId()
    if openDocuments[id].isModified then
        local saved = false
        if not openDocuments[id].fullpath then
            local ret = wx.wxMessageBox("You must save the program before running it.\nPress cancel to abort running.",
                                         "Save file?",  wx.wxOK + wx.wxCANCEL + wx.wxCENTRE, frame)
            if ret == wx.wxOK then
                saved = SaveFileAs(editor)
            end
        else
            saved = SaveFile(editor, openDocuments[id].fullpath)
        end

        if saved then
            openDocuments[id].isModified = false
        else
            return false -- not saved
        end
    end

    return true -- saved
end

local proc, streamOut, streamErr, streamIn

function ReadStream()
    local function doRead(stream)
        if stream and stream:CanRead() then
            local str = stream:Read(4096)
            DisplayOutput(str)
        else
            console:SetReadOnly(false)
        end
    end
    doRead(streamIn)
    doRead(streamErr)
end

function WriteStream(s)
    if streamOut then streamOut:Write(s, #s) end
end

local execTimer = wx.wxTimer(frame)

frame:Connect(wx.wxEVT_TIMER, ReadStream)

function ExpandCommand(cmd, doc)
    cmd = cmd:gsub("#%a+", {
        ["#program"]   = app.programName .. ' ' .. app.scriptName,
        ["#fullpath"]  = doc.fullpath,
        ["#directory"] = doc.directory,
        ["#fullname"]  = doc.fullname,
        ["#basename"]  = doc.basename,
        ["#suffix"]    = doc.suffix,
    })
    return cmd
end

function ExecCommand(cmd, dir)
    proc = wx.wxProcess()
    proc:Redirect()
    proc:Connect(wx.wxEVT_END_PROCESS,
        function(event)
            execTimer:Stop();
            ReadStream()
            proc = nil
        end)

    if menuBar:IsChecked(ID.CLEAROUTPUT) then
        ClearOutput()
        consoleLength = 0
    end
    DisplayOutput("Running program: "..cmd.."\n")
    local cwd = wx.wxGetCwd()
    wx.wxSetWorkingDirectory(dir)
    local pid = wx.wxExecute(cmd, wx.wxEXEC_ASYNC, proc)
    wx.wxSetWorkingDirectory(cwd)

    if pid == -1 then
        DisplayOutput("Unknown ERROR Running program!\n", true)
    else
        streamIn = proc and proc:GetInputStream()
        streamErr = proc and proc:GetErrorStream()
        streamOut = proc and proc:GetOutputStream()
        execTimer:Start(200);
    end
end

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

frame:Connect(ID.COMPILE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor();
            if not SaveIfModified(editor) then
                return
            end

            local id = editor:GetId();
            local cmd = app.setting.command.compile
            if cmd then
                cmd = ExpandCommand(cmd, openDocuments[id])
                ExecCommand(cmd, openDocuments[id].directory)
            end
        end)
frame:Connect(ID.COMPILE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor ~= nil)
        end)

frame:Connect(ID.PREVIEW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor();
            local id = editor:GetId();
            local cmd = app.setting.command.preview
            if cmd then
                cmd = ExpandCommand(cmd, openDocuments[id])
                ExecCommand(cmd, openDocuments[id].directory)
            end
        end)
frame:Connect(ID.PREVIEW, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor ~= nil)
        end)

frame:Connect(ID.SHOWHIDEWINDOW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if splitter:IsSplit() then
                splitter:Unsplit()
            else
                local w, h = frame:GetClientSizeWH()
                splitter:SplitHorizontally(notebook, console, (2 * h) / 3)
            end
        end)

function ClearOutput()
    console:SetReadOnly(false)
    console:ClearAll()
    console:SetReadOnly(true)
end
