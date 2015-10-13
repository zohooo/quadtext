-- ---------------------------------------------------------------------------
-- Create the File menu and attach the callback functions

local ID_NEW              = wx.wxID_NEW
local ID_OPEN             = wx.wxID_OPEN
local ID_CLOSE            = NewID()
local ID_SAVE             = wx.wxID_SAVE
local ID_SAVEAS           = wx.wxID_SAVEAS
local ID_SAVEALL          = NewID()
local ID_EXIT             = wx.wxID_EXIT
local ID_PRINT            = wx.wxID_PRINT
local ID_PRINT_PREVIEW    = NewID()
local ID_PAGE_SETUP       = wx.wxID_PAGE_SETUP

fileMenu = wx.wxMenu({
        { ID_NEW,     "&New\tCtrl-N",        "Create an empty document" },
        { ID_OPEN,    "&Open...\tCtrl-O",    "Open an existing document" },
        { ID_CLOSE,   "&Close page\tCtrl+W", "Close the current editor window" },
        { },
        { ID_SAVE,    "&Save\tCtrl-S",       "Save the current document" },
        { ID_SAVEAS,  "Save &As...\tAlt-S",  "Save the current document to a file with a new name" },
        { ID_SAVEALL, "Save A&ll...\tCtrl-Shift-S", "Save all open documents" },
        { },
        { ID_PRINT,         "&Print... \tCtrl-p",               "Print document"},
        { ID_PRINT_PREVIEW, "&Print Preview... \tShift-Ctrl-p", "Print preview"},
        { ID_PAGE_SETUP,    "Page S&etup...",                   "Set up printing"},
        { },
        { ID_EXIT,    "E&xit\tAlt-X",        "Exit Program" }})
menuBar:Append(fileMenu, "&File")

toolBar:AddTool(ID_NEW, "New",
                wx.wxArtProvider.GetBitmap(wx.wxART_NORMAL_FILE, wx.wxART_MENU, toolBmpSize),
                "Create an empty document")
toolBar:AddTool(ID_OPEN, "Open",
                wx.wxArtProvider.GetBitmap(wx.wxART_FILE_OPEN, wx.wxART_MENU, toolBmpSize),
                "Open an existing document")
toolBar:AddTool(ID_SAVE, "Save",
                wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize),
                "Save the current document")
toolBar:AddTool(ID_SAVEALL, "Save All",
                wx.wxArtProvider.GetBitmap(wx.wxART_NEW_DIR, wx.wxART_MENU, toolBmpSize),
                "Save all documents")

function NewFile(event)
    local editor = CreateEditor("untitled.tex")
    SetupKeywords(editor, "tex")
end

frame:Connect(ID_NEW, wx.wxEVT_COMMAND_MENU_SELECTED, NewFile)

-- Find an editor page that hasn't been used at all, eg. an untouched NewFile()
function FindDocumentToReuse()
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

function LoadFile(fullpath, editor, file_must_exist)
    local file_text, _ = ""
    local handle = wx.wxFile(fullpath, wx.wxFile.read)
    if handle:IsOpened() then
        _, file_text = handle:Read(wx.wxFileSize(fullpath))
        handle:Close()
    elseif file_must_exist then
        return nil
    end

    if not editor then
        editor = FindDocumentToReuse()
    end
    if not editor then
        editor = CreateEditor(wx.wxFileName(fullpath):GetFullName() or "untitled.tex")
     end

    editor:Clear()
    editor:ClearAll()
    editor:MarkerDeleteAll(CURRENT_LINE_MARKER)
    editor:AppendText(file_text)
    editor:EmptyUndoBuffer()
    local id = editor:GetId()
    local fp = wx.wxFileName(fullpath)
    openDocuments[id].fullpath = fullpath
    openDocuments[id].fullname = fp:GetFullName()
    openDocuments[id].directory = fp:GetPath(wx.wxPATH_GET_VOLUME)
    openDocuments[id].basename = fp:GetName()
    openDocuments[id].suffix = fp:GetExt()
    openDocuments[id].modTime = GetFileModTime(fullpath)
    SetDocumentModified(id, false)
    SetupKeywords(editor, fp:GetExt())
    editor:Colourise(0, -1)

    return editor
end

function OpenFile(event)
    local fileDialog = wx.wxFileDialog(frame, "Open file",
                                       "",
                                       "",
                                       "TeX files (*.tex)|*.tex|Lua files (*.lua)|*.lua|All files (*)|*",
                                       wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
        if not LoadFile(fileDialog:GetPath(), nil, true) then
            wx.wxMessageBox("Unable to load file '"..fileDialog:GetPath().."'.",
                            "wxLua Error",
                            wx.wxOK + wx.wxCENTRE, frame)
        end
    end
    fileDialog:Destroy()
end
frame:Connect(ID_OPEN, wx.wxEVT_COMMAND_MENU_SELECTED, OpenFile)

-- save the file to fullpath or if fullpath is nil then call SaveFileAs
function SaveFile(editor, fullpath)
    if not fullpath then
        return SaveFileAs(editor)
    else
        local backPath = fullpath..".bak"
        os.remove(backPath)
        os.rename(fullpath, backPath)

        local handle = wx.wxFile(fullpath, wx.wxFile.write)
        if handle:IsOpened() then
            local st = editor:GetText()
            handle:Write(st, #st)
            handle:Close()
            editor:EmptyUndoBuffer()
            local id = editor:GetId()
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

frame:Connect(ID_SAVE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor   = GetEditor()
            local id       = editor:GetId()
            local fullpath = openDocuments[id].fullpath
            SaveFile(editor, fullpath)
        end)

frame:Connect(ID_SAVE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            if editor then
                local id = editor:GetId()
                if openDocuments[id] then
                    event:Enable(openDocuments[id].isModified)
                end
            end
        end)

function SaveFileAs(editor)
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

        if save_file and SaveFile(editor, fullpath) then
            SetupKeywords(editor, wx.wxFileName(fullpath):GetExt())
            saved = true
        end
    end

    fileDialog:Destroy()
    return saved
end

frame:Connect(ID_SAVEAS, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            SaveFileAs(editor)
        end)
frame:Connect(ID_SAVEAS, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor ~= nil)
        end)

function SaveAll()
    for id, document in pairs(openDocuments) do
        local editor   = document.editor
        local fullpath = document.fullpath

        if document.isModified then
            SaveFile(editor, fullpath) -- will call SaveFileAs if necessary
        end
    end
end

frame:Connect(ID_SAVEALL, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            SaveAll()
        end)

frame:Connect(ID_SAVEALL, wx.wxEVT_UPDATE_UI,
        function (event)
            local atLeastOneModifiedDocument = false
            for id, document in pairs(openDocuments) do
                if document.isModified then
                    atLeastOneModifiedDocument = true
                    break
                end
            end
            event:Enable(atLeastOneModifiedDocument)
        end)


--> Printing
local printInfo = {
    pageSetupDialogData = wx.wxPageSetupDialogData(),
    printDialogData     = wx.wxPrintDialogData()
}
printInfo.pageSetupDialogData.MarginTopLeft     = wx.wxPoint(10, 10)
printInfo.pageSetupDialogData.MarginBottomRight = wx.wxPoint(10, 10)
printInfo.pageSetupDialogData:EnableOrientation(false)
printInfo.pageSetupDialogData:EnablePaper(false)
printInfo.pageSetupDialogData:SetPaperId(wx.wxPAPER_LETTER)

function printInfo.PrintScaling(dc, printOut)
    -- Get the whole size of the page in mm
    local pageSizeMM_x, pageSizeMM_y = printOut:GetPageSizeMM()

    -- Get the ppi of the screen and printer
    local ppiScr_x, ppiScr_y = printOut:GetPPIScreen()
    local ppiPrn_x, ppiPrn_y = printOut:GetPPIPrinter()

    local ppi_scale_x = ppiPrn_x/ppiScr_x
    local ppi_scale_y = ppiPrn_y/ppiScr_y

    -- Get the size of DC in pixels and the number of pixels in the page
    local dcSize_x, dcSize_y = dc:GetSize()
    local pagePixSize_x, pagePixSize_y = printOut:GetPageSizePixels()

    local dc_pagepix_scale_x = dcSize_x/pagePixSize_x
    local dc_pagepix_scale_y = dcSize_y/pagePixSize_y

    -- If printer pageWidth == current DC width, then this doesn't
    -- change. But w might be the preview bitmap width, so scale down.
    local dc_scale_x = ppi_scale_x * dc_pagepix_scale_x;
    local dc_scale_y = ppi_scale_y * dc_pagepix_scale_y;

    -- calculate the pixels / mm (25.4 mm = 1 inch)
    local ppmm_x = ppiScr_x / 25.4;
    local ppmm_y = ppiScr_y / 25.4;

    -- Adjust the page size for the pixels / mm scaling factor
    --wxSize paperSize = GetPageSetupData(true)->GetPaperSize();
    local page_x    = math.floor(pageSizeMM_x * ppmm_x);
    local page_y    = math.floor(pageSizeMM_y * ppmm_y);
    local pageRect  = wx.wxRect(0, 0, page_x, page_y);

    -- get margins informations and convert to printer pixels
    local topLeft     = printInfo.pageSetupDialogData.MarginTopLeft
    local bottomRight = printInfo.pageSetupDialogData.MarginBottomRight

    local top    = math.floor(topLeft.y     * ppmm_y);
    local bottom = math.floor(bottomRight.y * ppmm_y);
    local left   = math.floor(topLeft.x     * ppmm_x);
    local right  = math.floor(bottomRight.x * ppmm_x);

    dc:SetUserScale(dc_scale_x, dc_scale_y);

    local printRect = wx.wxRect(left, top, page_x-(left+right), page_y-(top+bottom));
    return printRect, pageRect
end

function printInfo:ConnectPrintEvents(printOut)
    local pages = {}

    function printOut:OnPrintPage(pageNum)
        local dc = self:GetDC()
        local editor = GetEditor()

        local printRect, pageRect = printInfo.PrintScaling(dc, printOut)

        -- Print to an area smaller by the height of the header
        dc:SetFont(font)
        local _, headerHeight = dc:GetTextExtent("qH")
        local textRect = wx.wxRect(printRect)
        textRect:SetY(textRect:GetY() + headerHeight*1.5)
        textRect:SetHeight(textRect:GetHeight() - headerHeight*1.5)

        if pageNum == nil then
            local progDialog = wx.wxProgressDialog("Formatting printout",
                                                   "Page 1 of ?             ",
                                                   100, editor, wx.wxPD_AUTO_HIDE)
            progDialog:SetFocus() -- grab focus from wxPreviewFrame

            pages = {}
            local pos = 1
            local length = editor:GetLength()
            local lines  = editor:GetLineCount()

            while pos < length do
                table.insert(pages, pos)
                pos = editor:FormatRange(false, pos, length, dc, dc, textRect, pageRect)

                local current_line = editor:LineFromPosition(iff(pos-1 > 0, pos-1, 0))
                current_line = iff(current_line > 1, current_line, 1)
                local page_count = 1+(#pages)*lines/current_line;
                progDialog:Update(math.floor(pos*100.0/length),
                                  string.format("Page %d of %d", #pages, page_count))
            end

            if #pages == 0 then
                pages = {1}
            end

            progDialog:Destroy()
        else
            editor:FormatRange(true, pages[pageNum], editor.Length, dc, dc, textRect, pageRect);

            local pageNo = 'Page '..pageNum

            dc:SetPen(wx.wxBLACK_PEN)
            dc:SetTextForeground(wx.wxBLACK)
            dc:SetFont(font)

            dc:DrawText(openDocuments[editor:GetId()].fullname or "untitled.tex", printRect.X, printRect.Y)
            dc:DrawText(printOut.startTime, printRect.Width/2 - dc:GetTextExtentSize(printOut.startTime).Width/2 + printRect.Left, printRect.Y)
            dc:DrawText(pageNo, printRect.Width - dc:GetTextExtentSize(pageNo).Width,  printRect.Y)
            dc:DrawLine(printRect.X,     printRect.Y + headerHeight + 1,
                        printRect.Width, printRect.Y + headerHeight + 1)
        end
        return true
    end
    function printOut:HasPage(pageNum) return pageNum <= #pages end
    function printOut:GetPageInfo()    return 1, #pages, 1, #pages end
    function printOut:OnPreparePrinting()
        printOut.startTime = wx.wxNow()
        printOut:OnPrintPage()
    end
end

function PrintPreview()
    local printerPrintout = wx.wxLuaPrintout("wxLua Printout")
    printInfo:ConnectPrintEvents(printerPrintout)

    local previewPrintout = wx.wxLuaPrintout("wxLua Print Preview")
    printInfo:ConnectPrintEvents(previewPrintout)

    local preview = wx.wxPrintPreview(printerPrintout, previewPrintout, printInfo.printDialogData:GetPrintData())
    local result = preview:Ok()
    if result == false then
        wx.wxMessageBox("There was a problem previewing.\nPerhaps your current printer is not set correctly?",
                        "Printing.wx.lua",
                        wx.wxOK)
    else
        local previewFrame = wx.wxPreviewFrame(preview, frame,
                                               "wxLua Print Preview",
                                               wx.wxDefaultPosition,
                                               wx.wxSize(600, 650),
                                               wx.wxDEFAULT_FRAME_STYLE + wx.wxFRAME_FLOAT_ON_PARENT)

        previewFrame:Connect(wx.wxEVT_CLOSE_WINDOW,
                function (event)
                    previewFrame:Destroy()
                    event:Skip()
                end )

        previewFrame:Centre(wx.wxBOTH)
        previewFrame:Initialize()
        previewFrame:Raise()
        previewFrame:Show(true)
    end
end

frame:Connect(ID_PAGE_SETUP, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        local pageSetupDialog = wx.wxPageSetupDialog(frame, printInfo.pageSetupDialogData)
        pageSetupDialog:ShowModal()
        printInfo.pageSetupDialogData = pageSetupDialog:GetPageSetupDialogData()
    end)

frame:Connect(ID_PRINT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        local editor = GetEditor()
        -- The default size is too large, this gets ~80 rows for a 12 pt font
        editor:SetPrintMagnification(-2)

        local printer  = wx.wxPrinter(printInfo.printDialogData)
        local luaPrintout = wx.wxLuaPrintout()
        printInfo:ConnectPrintEvents(luaPrintout)
        if printer:Print(frame, luaPrintout, true) == false then
            if printer:GetLastError() == wx.wxPRINTER_ERROR then
                wx.wxMessageBox("There was a problem printing.\nPerhaps your current printer is not set correctly?", "wxLua", wx.wxOK)
            --elseif err == wx.wxPRINTER_CANCELLED then
            --    wx.wxMessageBox("You cancelled printing", "wxLua", wx.wxOK)
            end
        end
    end)

frame:Connect(ID_PRINT_PREVIEW, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        local editor = GetEditor()
        -- The default size is too large, this gets ~80 rows for a 12 pt font
        editor:SetPrintMagnification(-2)

        PrintPreview()
    end)

function RemovePage(index)
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
function SaveModifiedDialog(editor, allow_cancel)
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
            SaveFile(editor, fullpath)
        end
    end

    return result
end

frame:Connect(ID_CLOSE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            local id     = editor:GetId()
            if SaveModifiedDialog(editor, true) ~= wx.wxID_CANCEL then
                RemovePage(openDocuments[id].index)
            end
        end)

frame:Connect(ID_CLOSE, wx.wxEVT_UPDATE_UI,
        function (event)
            event:Enable(GetEditor() ~= nil)
        end)

function SaveOnExit(allow_cancel)
    for id, document in pairs(openDocuments) do
        if (SaveModifiedDialog(document.editor, allow_cancel) == wx.wxID_CANCEL) then
            return false
        end

        document.isModified = false
    end

    return true
end

frame:Connect( ID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if not SaveOnExit(true) then return end
            frame:Close() -- will handle wxEVT_CLOSE_WINDOW
        end)
