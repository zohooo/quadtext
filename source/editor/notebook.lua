
-- ----------------------------------------------------------------------------
-- wxNotebook of editors

notebook = wx.wxNotebook(splitter, wx.wxID_ANY,
                         wx.wxDefaultPosition, wx.wxDefaultSize,
                         wx.wxCLIP_CHILDREN)

notebook.openDocuments = {}
-- open notebook editor documents[winId] = {
--   editor     = wxStyledTextCtrl,
--   index      = wxNotebook page index,
--   encoding   = file encoding,
--   fullpath   = full filepath, nil if not saved,
--   fullname   = full filename with extension,
--   directory  = filepath without filename,
--   basename   = filename without extension,
--   suffix     = filename extension,
--   modTime    = wxDateTime of disk file or nil,
--   isModified = bool is the document modified? }

-- ----------------------------------------------------------------------------
-- Create an editor and add it to the notebook
function notebook:AddEditor(name)
    local editor = app:CreateEditor(notebook, wx.wxDefaultPosition,
                                    wx.wxDefaultSize, wx.wxSUNKEN_BORDER)

    if notebook:AddPage(editor, name, true) then
        local id            = editor:GetId()
        local document      = {}
        document.editor     = editor
        document.index      = notebook:GetSelection()
        document.fullname   = nil
        document.fullpath   = nil
        document.modTime    = nil
        document.isModified = false
        self.openDocuments[id]   = document
    end

    return editor
end

-- Get/Set notebook editor page, use nil for current page, returns nil if none
function notebook:GetEditor(selection)
    local editor = nil
    if selection == nil then
        selection = notebook:GetSelection()
    end
    if (selection >= 0) and (selection < notebook:GetPageCount()) then
        editor = notebook:GetPage(selection):DynamicCast("wxStyledTextCtrl")
    end
    return editor
end

-- init new notebook page selection, use nil for current page
function notebook:SetEditorSelection(selection)
    local editor = notebook:GetEditor(selection)
    if editor then
        editor:SetFocus()
        editor:SetSTCFocus(true)
        filer:IsFileAlteredOnDisk(editor)
    end
    statusbar:UpdateStatusText(editor) -- update even if nil
end

-- remove notebook editor page
function notebook:RemoveEditor(index)
    local newIndex = nil
    local editorId = nil

    for id, document in pairs(self.openDocuments) do
        if document.index == index then
            document.editor:Destroy()
            editorId = id
        elseif document.index > index then
            document.index = document.index - 1
        end
    end

    self.openDocuments[editorId] = nil
    self:RemovePage(index)

    newIndex = iff(self:GetPageCount() > index, index, index - 1)
    if newIndex >=0 then
        self:SetSelection(newIndex)
    end

    self:SetEditorSelection(nil) -- will use notebook GetSelection to update
end

-- ----------------------------------------------------------------------------
-- Set if the document is modified and update the notebook page text
function notebook:SetDocumentModified(id, modified)
    local pageText = self.openDocuments[id].fullname or "untitled.tex"

    if modified then
        pageText = "* "..pageText
    end

    self.openDocuments[id].isModified = modified
    notebook:SetPageText(self.openDocuments[id].index, pageText)
end

function notebook:SetAllEditorsReadOnly(enable)
    for id, document in pairs(self.openDocuments) do
        local editor = document.editor
        editor:SetReadOnly(enable)
    end
end

-- ----------------------------------------------------------------------------
-- drag and drop to open files

local notebookFileDropTarget = wx.wxLuaFileDropTarget();

notebookFileDropTarget.OnDropFiles = function(self, x, y, filenames)
                                        for i = 1, #filenames do
                                            filer:LoadFile(filenames[i], nil, true)
                                        end
                                        return true
                                     end

notebook:SetDropTarget(notebookFileDropTarget)

-- ----------------------------------------------------------------------------
-- attach callback functions to notebook

notebook:Connect(wx.wxEVT_COMMAND_NOTEBOOK_PAGE_CHANGED,
        function (event)
            if not frame.exitingProgram then
                notebook:SetEditorSelection(event:GetSelection())
            end
            event:Skip() -- skip to let page change
        end)
