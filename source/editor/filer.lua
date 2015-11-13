
filer = {}

function filer:NewFile(event)
    local editor = CreateEditor("untitled.tex")
    frame:SetupEditor(editor, "tex")
end

-- Find an editor page that hasn't been used at all, eg. an untouched NewFile()
local function FindDocumentToReuse()
    local editor = nil
    for id, document in pairs(openDocuments) do
        if (document.editor:GetLength() == 0) and
           (not document.isModified) and (not document.fullpath) and
           not (document.editor:GetReadOnly() == true) then
            editor = document.editor
            break
        end
    end
    return editor
end

local function FindDocumentOpened(path)
    for _, doc in pairs(openDocuments) do
        if doc.fullpath == path then return doc end
    end
    return nil
end

function filer:LoadFile(fullpath, editor, file_must_exist)
    -- If this file has been opened
    if not editor then
        local doc = FindDocumentOpened(fullpath)
        if doc then
            notebook:SetSelection(doc.index)
            return doc.editor
        end
    end

    local file_text, _ = ""
    local handle = wx.wxFile(fullpath, wx.wxFile.read)
    if handle:IsOpened() then
        _, file_text = handle:Read(wx.wxFileSize(fullpath))
        handle:Close()
    elseif file_must_exist then
        return nil
    end

    -- detect text encoding and convert its encoding to utf-8
    local enc, text = encoding:Detect(file_text)
    if not enc then return end

    if not editor then
        editor = FindDocumentToReuse()
    end
    if not editor then
        editor = CreateEditor(wx.wxFileName(fullpath):GetFullName() or "untitled.tex")
    end

    editor:Clear()
    editor:ClearAll()
    editor:MarkerDeleteAll(CURRENT_LINE_MARKER)
    editor:AppendText(text)
    editor:EmptyUndoBuffer()
    local id = editor:GetId()
    local fp = wx.wxFileName(fullpath)
    openDocuments[id].encoding = enc
    openDocuments[id].fullpath = fullpath
    openDocuments[id].fullname = fp:GetFullName()
    openDocuments[id].directory = fp:GetPath(wx.wxPATH_GET_VOLUME)
    openDocuments[id].basename = fp:GetName()
    openDocuments[id].suffix = fp:GetExt()
    openDocuments[id].modTime = GetFileModTime(fullpath)
    SetDocumentModified(id, false)
    frame:SetupEditor(editor, fp:GetExt())

    return editor
end

function filer:OpenFile(event)
    local fileDialog = wx.wxFileDialog(frame, "Open file",
                                       "",
                                       "",
                                       "TeX files (*.tex)|*.tex|Lua files (*.lua)|*.lua|All files (*)|*",
                                       wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
        if not filer:LoadFile(fileDialog:GetPath(), nil, true) then
            wx.wxMessageBox("Unable to load file '"..fileDialog:GetPath().."'.",
                            "wxLua Error",
                            wx.wxOK + wx.wxCENTRE, frame)
        end
    end
    fileDialog:Destroy()
end

-- save the file to fullpath or if fullpath is nil then call SaveFileAs
function filer:SaveFile(editor, fullpath)
    if not fullpath then
        return filer:SaveFileAs(editor)
    else
        local backPath = fullpath..".bak"
        os.remove(backPath)
        os.rename(fullpath, backPath)

        local text = editor:GetText()
        local id = editor:GetId()
        local enc = openDocuments[id].encoding
        if enc then
            text = encoding:Convert(text, "UTF-8", enc)
            if not text then
                wx.wxMessageBox("Unable to convert file encoding!",
                        "Error Saving", wx.wxOK + wx.wxCENTRE, frame)
                return false
            end
        end

        local handle = wx.wxFile(fullpath, wx.wxFile.write)
        if handle:IsOpened() then
            handle:Write(text, #text)
            handle:Close()
            editor:EmptyUndoBuffer()
            local fp = wx.wxFileName(fullpath)
            openDocuments[id].fullpath = fullpath
            openDocuments[id].fullname = fp:GetFullName()
            openDocuments[id].directory = fp:GetPath(wx.wxPATH_GET_VOLUME)
            openDocuments[id].basename = fp:GetName()
            openDocuments[id].suffix = fp:GetExt()
            openDocuments[id].modTime  = GetFileModTime(fullpath)
            SetDocumentModified(id, false)
            return true
        else
            wx.wxMessageBox("Unable to save file '"..fullpath.."'.",
                            "wxLua Error Saving",
                            wx.wxOK + wx.wxCENTRE, frame)
        end
    end

    return false
end

function filer:SaveFileAs(editor)
    local id       = editor:GetId()
    local saved    = false
    local fn       = wx.wxFileName(openDocuments[id].fullpath or "")
    fn:Normalize() -- want absolute path for dialog

    local fileDialog = wx.wxFileDialog(frame, "Save file as",
                                       fn:GetPath(),
                                       fn:GetFullName(),
                                       "TeX files (*.tex)|*.tex|Lua files (*.lua)|*.lua|All files (*)|*",
                                       wx.wxFD_SAVE + wx.wxFD_OVERWRITE_PROMPT)

    if fileDialog:ShowModal() == wx.wxID_OK then
        local fullpath = fileDialog:GetPath()

        local save_file = true

        if wx.wxFileExists(fullpath) then
            save_file = (wx.wxYES == wx.wxMessageBox(string.format("Replace file:\n%s", fullpath), "wxLua Overwrite File",
                                                     wx.wxYES_NO + wx.wxICON_QUESTION, frame))
        end

        if save_file and filer:SaveFile(editor, fullpath) then
            frame:SetupEditor(editor, wx.wxFileName(fullpath):GetExt())
            saved = true
        end
    end

    fileDialog:Destroy()
    return saved
end

function filer:SaveAll()
    for id, document in pairs(openDocuments) do
        local editor   = document.editor
        local fullpath = document.fullpath

        if document.isModified then
            filer:SaveFile(editor, fullpath) -- will call SaveFileAs if necessary
        end
    end
end

function filer:RemovePage(index)
    local  prevIndex = nil
    local  nextIndex = nil
    local newOpenDocuments = {}

    for id, document in pairs(openDocuments) do
        if document.index < index then
            newOpenDocuments[id] = document
            prevIndex = document.index
        elseif document.index == index then
            document.editor:Destroy()
        elseif document.index > index then
            document.index = document.index - 1
            if nextIndex == nil then
                nextIndex = document.index
            end
            newOpenDocuments[id] = document
        end
    end

    notebook:RemovePage(index)
    openDocuments = newOpenDocuments

    if nextIndex then
        notebook:SetSelection(nextIndex)
    elseif prevIndex then
        notebook:SetSelection(prevIndex)
    end

    SetEditorSelection(nil) -- will use notebook GetSelection to update
end

-- Show a dialog to save a file before closing editor.
--   returns wxID_YES, wxID_NO, or wxID_CANCEL if allow_cancel
function filer:SaveModifiedDialog(editor, allow_cancel)
    local result   = wx.wxID_NO
    local id       = editor:GetId()
    local document = openDocuments[id]
    local fullpath = document.fullpath
    local fullname = document.fullname
    if document.isModified then
        local message
        if fullname then
            message = "Save changes to '"..fullname.."' before exiting?"
        else
            message = "Save changes to 'untitled' before exiting?"
        end
        local dlg_styles = wx.wxYES_NO + wx.wxCENTRE + wx.wxICON_QUESTION
        if allow_cancel then dlg_styles = dlg_styles + wx.wxCANCEL end
        local dialog = wx.wxMessageDialog(frame, message,
                                          "Save Changes?",
                                          dlg_styles)
        result = dialog:ShowModal()
        dialog:Destroy()
        if result == wx.wxID_YES then
            filer:SaveFile(editor, fullpath)
        end
    end

    return result
end

function filer:SaveOnExit(allow_cancel)
    for id, document in pairs(openDocuments) do
        if (filer:SaveModifiedDialog(document.editor, allow_cancel) == wx.wxID_CANCEL) then
            return false
        end
        document.isModified = false
    end
    return true
end
