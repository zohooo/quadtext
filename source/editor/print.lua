
printing = {
    pageSetupDialogData = wx.wxPageSetupDialogData(),
    printDialogData     = wx.wxPrintDialogData()
}
printing.pageSetupDialogData.MarginTopLeft     = wx.wxPoint(10, 10)
printing.pageSetupDialogData.MarginBottomRight = wx.wxPoint(10, 10)
printing.pageSetupDialogData:EnableOrientation(false)
printing.pageSetupDialogData:EnablePaper(false)
printing.pageSetupDialogData:SetPaperId(wx.wxPAPER_LETTER)

function printing.PrintScaling(dc, printOut)
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
    local topLeft     = printing.pageSetupDialogData.MarginTopLeft
    local bottomRight = printing.pageSetupDialogData.MarginBottomRight

    local top    = math.floor(topLeft.y     * ppmm_y);
    local bottom = math.floor(bottomRight.y * ppmm_y);
    local left   = math.floor(topLeft.x     * ppmm_x);
    local right  = math.floor(bottomRight.x * ppmm_x);

    dc:SetUserScale(dc_scale_x, dc_scale_y);

    local printRect = wx.wxRect(left, top, page_x-(left+right), page_y-(top+bottom));
    return printRect, pageRect
end

function printing:ConnectPrintEvents(printOut)
    local pages = {}

    function printOut:OnPrintPage(pageNum)
        local dc = self:GetDC()
        local editor = GetEditor()

        local printRect, pageRect = printing.PrintScaling(dc, printOut)

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

function printing:Print()
    local printer  = wx.wxPrinter(printing.printDialogData)
    local luaPrintout = wx.wxLuaPrintout()
    printing:ConnectPrintEvents(luaPrintout)
    if printer:Print(frame, luaPrintout, true) == false then
        if printer:GetLastError() == wx.wxPRINTER_ERROR then
            wx.wxMessageBox("There was a problem printing.\nPerhaps your current printer is not set correctly?", "wxLua", wx.wxOK)
        --elseif err == wx.wxPRINTER_CANCELLED then
        --    wx.wxMessageBox("You cancelled printing", "wxLua", wx.wxOK)
        end
    end
end

function printing:PrintPreview()
    local printerPrintout = wx.wxLuaPrintout("wxLua Printout")
    printing:ConnectPrintEvents(printerPrintout)

    local previewPrintout = wx.wxLuaPrintout("wxLua Print Preview")
    printing:ConnectPrintEvents(previewPrintout)

    local preview = wx.wxPrintPreview(printerPrintout, previewPrintout, printing.printDialogData:GetPrintData())
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

function printing:PageSetup()
    local pageSetupDialog = wx.wxPageSetupDialog(frame, printing.pageSetupDialogData)
    pageSetupDialog:ShowModal()
    printing.pageSetupDialogData = pageSetupDialog:GetPageSetupDialogData()
end
