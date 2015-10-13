-- ---------------------------------------------------------------------------
-- Create the Tool menu and attach the callback functions

local ID_COMPILE          = NewID()
local ID_PREVIEW          = NewID()
local ID_SHOWHIDEWINDOW   = NewID()
local ID_CLEAROUTPUT      = NewID()

toolMenu = wx.wxMenu{
        { ID_COMPILE,          "&Compile\tF5",          "Compile current file" },
        { ID_PREVIEW,          "&Preview\tF6",          "Preview output file" },
        { },
        { ID_SHOWHIDEWINDOW,   "View &Output Window\tF8", "View or Hide the output window" },
        { ID_CLEAROUTPUT,      "C&lear Output Window",    "Clear the output window before compiling", wx.wxITEM_CHECK },
        }
menuBar:Append(toolMenu, "&Tool")

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

function DisplayOutput(message, dont_add_marker)
    if splitter:IsSplit() == false then
        local w, h = frame:GetClientSizeWH()
        splitter:SplitHorizontally(notebook, errorLog, (2 * h) / 3)
    end
    if not dont_add_marker then
        errorLog:MarkerAdd(errorLog:GetLineCount()-1, CURRENT_LINE_MARKER)
    end
    errorLog:SetReadOnly(false)
    errorLog:AppendText(message)
    errorLog:SetReadOnly(true)
    errorLog:GotoPos(errorLog:GetLength())
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

frame:Connect(ID_COMPILE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor();
            if not SaveIfModified(editor) then
                return
            end

            local id = editor:GetId();
            programName = "xelatex"
            local texName = openDocuments[id].fullname
            local cmd = 'cmd /k start "" '..programName..' "'..texName..'" & exit'

            DisplayOutput("Running program: "..cmd.."\n")
            local cwd = wx.wxGetCwd()
            wx.wxSetWorkingDirectory(openDocuments[id].directory)
            local pid = wx.wxExecute(cmd, wx.wxEXEC_ASYNC)
            wx.wxSetWorkingDirectory(cwd)
            print(pid)

            if pid == -1 then
                DisplayOutput("Unknown ERROR Running program!\n", true)
            else
                DisplayOutput("Process id is: "..tostring(pid).."\n", true)
            end
        end)
frame:Connect(ID_COMPILE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor ~= nil)
        end)

frame:Connect(ID_PREVIEW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor();

            local id = editor:GetId();
            programName = "SumatraPDF"
            local pdfName = openDocuments[id].basename .. ".pdf"
            local cmd = programName .. ' ' .. pdfName

            DisplayOutput("Running program: "..cmd.."\n")
            local cwd = wx.wxGetCwd()
            wx.wxSetWorkingDirectory(openDocuments[id].directory)
            local pid = wx.wxExecute(cmd, wx.wxEXEC_ASYNC)
            wx.wxSetWorkingDirectory(cwd)
            print(pid)

            if pid == -1 then
                DisplayOutput("Unknown ERROR Running program!\n", true)
            else
                DisplayOutput("Process id is: "..tostring(pid).."\n", true)
            end
        end)
frame:Connect(ID_PREVIEW, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor ~= nil)
        end)

frame:Connect(ID_SHOWHIDEWINDOW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if splitter:IsSplit() then
                splitter:Unsplit()
            else
                local w, h = frame:GetClientSizeWH()
                splitter:SplitHorizontally(notebook, errorLog, (2 * h) / 3)
            end
        end)

function ClearOutput(event)
    errorLog:SetReadOnly(false)
    errorLog:ClearAll()
    errorLog:SetReadOnly(true)
end
