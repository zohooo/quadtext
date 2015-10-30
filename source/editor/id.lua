
-- Generate a unique new wxWindowID
local COUNTER = wx.wxID_HIGHEST + 1
function NewID()
    COUNTER = COUNTER + 1
    return COUNTER
end

ID = {}

-- File menu
ID.NEW                 = wx.wxID_NEW
ID.OPEN                = wx.wxID_OPEN
ID.CLOSE               = NewID()
ID.SAVE                = wx.wxID_SAVE
ID.SAVEAS              = wx.wxID_SAVEAS
ID.SAVEALL             = NewID()
ID.EXIT                = wx.wxID_EXIT
ID.PRINT               = wx.wxID_PRINT
ID.PRINT_PREVIEW       = NewID()
ID.PAGE_SETUP          = wx.wxID_PAGE_SETUP

-- Edit menu
ID.CUT                 = wx.wxID_CUT
ID.COPY                = wx.wxID_COPY
ID.PASTE               = wx.wxID_PASTE
ID.SELECTALL           = wx.wxID_SELECTALL
ID.UNDO                = wx.wxID_UNDO
ID.REDO                = wx.wxID_REDO
ID.AUTOCOMPLETE        = NewID()
ID.AUTOCOMPLETE_ENABLE = NewID()
ID.COMMENT             = NewID()
ID.FOLD                = NewID()

-- Search menu
ID.FIND                = wx.wxID_FIND
ID.FINDNEXT            = NewID()
ID.FINDPREV            = NewID()
ID.REPLACE             = NewID()
ID.GOTOLINE            = NewID()
ID.SORT                = NewID()

-- Tool menu
ID.COMPILE             = NewID()
ID.PREVIEW             = NewID()
ID.SHOWHIDEWINDOW      = NewID()
ID.CLEAROUTPUT         = NewID()

-- Option menu
ID.SETTING_EDITOR      = NewID()
ID.SETTING_COMMAND     = NewID()

-- Help menu
ID.ABOUT               = wx.wxID_ABOUT

-- Others
ID.SINGLETON           = NewID()
