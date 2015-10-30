
toolBar = frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)

-- note: Ususally the bmp size isn't necessary, but the HELP icon is not the right size in MSW
local toolBmpSize = toolBar:GetToolBitmapSize()

toolBar:AddTool(ID.NEW, "New",
                wx.wxArtProvider.GetBitmap(wx.wxART_NEW, wx.wxART_MENU, toolBmpSize),
                "Create an empty document")
toolBar:AddTool(ID.OPEN, "Open",
                wx.wxArtProvider.GetBitmap(wx.wxART_FILE_OPEN, wx.wxART_MENU, toolBmpSize),
                "Open an existing document")
toolBar:AddTool(ID.SAVE, "Save",
                wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize),
                "Save the current document")
toolBar:AddTool(ID.SAVEAS, "Save As",
                wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE_AS, wx.wxART_MENU, toolBmpSize),
                "Save current document with a new name")

toolBar:AddSeparator()

toolBar:AddTool(ID.CUT, "Cut",
                wx.wxArtProvider.GetBitmap(wx.wxART_CUT, wx.wxART_MENU, toolBmpSize),
                "Cut the selection")
toolBar:AddTool(ID.COPY, "Copy",
                wx.wxArtProvider.GetBitmap(wx.wxART_COPY, wx.wxART_MENU, toolBmpSize),
                "Copy the selection")
toolBar:AddTool(ID.PASTE, "Paste",
                wx.wxArtProvider.GetBitmap(wx.wxART_PASTE, wx.wxART_MENU, toolBmpSize),
                "Paste text from the clipboard")

toolBar:AddSeparator()

toolBar:AddTool(ID.UNDO, "Undo",
                wx.wxArtProvider.GetBitmap(wx.wxART_UNDO, wx.wxART_MENU, toolBmpSize),
                "Undo last edit")
toolBar:AddTool(ID.REDO, "Redo",
                wx.wxArtProvider.GetBitmap(wx.wxART_REDO, wx.wxART_MENU, toolBmpSize),
                "Redo last undo")

toolBar:AddSeparator()

toolBar:AddTool(ID.FIND, "Find",
                wx.wxArtProvider.GetBitmap(wx.wxART_FIND, wx.wxART_MENU, toolBmpSize),
                "Find text")
toolBar:AddTool(ID.REPLACE, "Replace",
                wx.wxArtProvider.GetBitmap(wx.wxART_FIND_AND_REPLACE, wx.wxART_MENU, toolBmpSize),
                "Find and replace text")

toolBar:Realize()
