
toolbar = frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)

-- note: Ususally the bmp size isn't necessary, but the HELP icon is not the right size in MSW
local toolBmpSize = toolbar:GetToolBitmapSize()

toolbar:AddTool(ID.NEW, "New",
                wx.wxArtProvider.GetBitmap(wx.wxART_NEW, wx.wxART_MENU, toolBmpSize),
                "Create an empty document")
toolbar:AddTool(ID.OPEN, "Open",
                wx.wxArtProvider.GetBitmap(wx.wxART_FILE_OPEN, wx.wxART_MENU, toolBmpSize),
                "Open an existing document")
toolbar:AddTool(ID.SAVE, "Save",
                wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize),
                "Save the current document")
toolbar:AddTool(ID.SAVEAS, "Save As",
                wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE_AS, wx.wxART_MENU, toolBmpSize),
                "Save current document with a new name")

toolbar:AddSeparator()

toolbar:AddTool(ID.CUT, "Cut",
                wx.wxArtProvider.GetBitmap(wx.wxART_CUT, wx.wxART_MENU, toolBmpSize),
                "Cut the selection")
toolbar:AddTool(ID.COPY, "Copy",
                wx.wxArtProvider.GetBitmap(wx.wxART_COPY, wx.wxART_MENU, toolBmpSize),
                "Copy the selection")
toolbar:AddTool(ID.PASTE, "Paste",
                wx.wxArtProvider.GetBitmap(wx.wxART_PASTE, wx.wxART_MENU, toolBmpSize),
                "Paste text from the clipboard")

toolbar:AddSeparator()

toolbar:AddTool(ID.UNDO, "Undo",
                wx.wxArtProvider.GetBitmap(wx.wxART_UNDO, wx.wxART_MENU, toolBmpSize),
                "Undo last edit")
toolbar:AddTool(ID.REDO, "Redo",
                wx.wxArtProvider.GetBitmap(wx.wxART_REDO, wx.wxART_MENU, toolBmpSize),
                "Redo last undo")

toolbar:AddSeparator()

toolbar:AddTool(ID.FIND, "Find",
                wx.wxArtProvider.GetBitmap(wx.wxART_FIND, wx.wxART_MENU, toolBmpSize),
                "Find text")
toolbar:AddTool(ID.REPLACE, "Replace",
                wx.wxArtProvider.GetBitmap(wx.wxART_FIND_AND_REPLACE, wx.wxART_MENU, toolBmpSize),
                "Find and replace text")

toolbar:Realize()
