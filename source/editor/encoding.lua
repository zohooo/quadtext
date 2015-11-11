
encoding = {}

local iconv = require("iconv")

local encList = app.setting.editor.encoding or {"UTF-8", "System"}

local dialog, listview = nil, nil

local lang2enc = {
    [wx.wxLANGUAGE_AFRIKAANS]                  = "CP1252",
    [wx.wxLANGUAGE_ALBANIAN]               = "CP1250",
    [wx.wxLANGUAGE_BASQUE]                     = "CP1252",
    [wx.wxLANGUAGE_CATALAN]                    = "CP1252",
    [wx.wxLANGUAGE_CHINESE_SIMPLIFIED]     = "CP936",
    [wx.wxLANGUAGE_CHINESE_TRADITIONAL]    = "CP950",
    [wx.wxLANGUAGE_CHINESE_HONGKONG]       = "CP950",
    [wx.wxLANGUAGE_CHINESE_MACAU]          = "CP950",
    [wx.wxLANGUAGE_CHINESE_SINGAPORE]      = "CP936",
    [wx.wxLANGUAGE_CHINESE_TAIWAN]         = "CP950",
    [wx.wxLANGUAGE_CROATIAN]               = "CP1250",
    [wx.wxLANGUAGE_CZECH]                  = "CP1250",
    [wx.wxLANGUAGE_DANISH]                     = "CP1252",
    [wx.wxLANGUAGE_DUTCH]                      = "CP1252",
    [wx.wxLANGUAGE_DUTCH_BELGIAN]              = "CP1252",
    [wx.wxLANGUAGE_ENGLISH]                    = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_UK]                 = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_US]                 = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_AUSTRALIA]          = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_BELIZE]             = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_BOTSWANA]           = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_CANADA]             = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_CARIBBEAN]          = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_DENMARK]            = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_EIRE]               = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_JAMAICA]            = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_NEW_ZEALAND]        = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_PHILIPPINES]        = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_SOUTH_AFRICA]       = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_TRINIDAD]           = "CP1252",
    [wx.wxLANGUAGE_ENGLISH_ZIMBABWE]           = "CP1252",
    [wx.wxLANGUAGE_ESTONIAN]               = "CP1257",
    [wx.wxLANGUAGE_FAEROESE]                   = "CP1252",
    [wx.wxLANGUAGE_FINNISH]                    = "CP1252",
    [wx.wxLANGUAGE_FRENCH]                     = "CP1252",
    [wx.wxLANGUAGE_FRENCH_BELGIAN]             = "CP1252",
    [wx.wxLANGUAGE_FRENCH_CANADIAN]            = "CP1252",
    [wx.wxLANGUAGE_FRENCH_LUXEMBOURG]          = "CP1252",
    [wx.wxLANGUAGE_FRENCH_MONACO]              = "CP1252",
    [wx.wxLANGUAGE_FRENCH_SWISS]               = "CP1252",
    [wx.wxLANGUAGE_GEORGIAN]                   = "CP1252",
    [wx.wxLANGUAGE_GERMAN]                     = "CP1252",
    [wx.wxLANGUAGE_GERMAN_AUSTRIAN]            = "CP1252",
    [wx.wxLANGUAGE_GERMAN_BELGIUM]             = "CP1252",
    [wx.wxLANGUAGE_GERMAN_LIECHTENSTEIN]       = "CP1252",
    [wx.wxLANGUAGE_GERMAN_LUXEMBOURG]          = "CP1252",
    [wx.wxLANGUAGE_GERMAN_SWISS]               = "CP1252",
    [wx.wxLANGUAGE_GREEK]                  = "CP1253",
    [wx.wxLANGUAGE_HUNGARIAN]              = "CP1250",
    [wx.wxLANGUAGE_ICELANDIC]                  = "CP1252",
    [wx.wxLANGUAGE_INDONESIAN]                 = "CP1252",
    [wx.wxLANGUAGE_ITALIAN]                    = "CP1252",
    [wx.wxLANGUAGE_ITALIAN_SWISS]              = "CP1252",
    [wx.wxLANGUAGE_JAPANESE]               = "CP932",
    [wx.wxLANGUAGE_KOREAN]                 = "CP949",
    [wx.wxLANGUAGE_LATVIAN]                = "CP1257",
    [wx.wxLANGUAGE_LITHUANIAN]             = "CP1257",
    [wx.wxLANGUAGE_MACEDONIAN]             = "CP1251",
    [wx.wxLANGUAGE_NORWEGIAN_BOKMAL]           = "CP1252",
    [wx.wxLANGUAGE_NORWEGIAN_NYNORSK]          = "CP1252",
    [wx.wxLANGUAGE_POLISH]                 = "CP1250",
    [wx.wxLANGUAGE_PORTUGUESE]                 = "CP1252",
    [wx.wxLANGUAGE_PORTUGUESE_BRAZILIAN]       = "CP1252",
    [wx.wxLANGUAGE_ROMANIAN]               = "CP1250",
    [wx.wxLANGUAGE_RUSSIAN]                = "CP1251",
    [wx.wxLANGUAGE_SERBIAN_CYRILLIC]       = "CP1251",
    [wx.wxLANGUAGE_SERBIAN_LATIN]          = "CP1251",
    [wx.wxLANGUAGE_SLOVAK]                 = "CP1250",
    [wx.wxLANGUAGE_SLOVENIAN]              = "CP1250",
    [wx.wxLANGUAGE_SPANISH]                    = "CP1252",
    [wx.wxLANGUAGE_SPANISH_ARGENTINA]          = "CP1252",
    [wx.wxLANGUAGE_SPANISH_BOLIVIA]            = "CP1252",
    [wx.wxLANGUAGE_SPANISH_CHILE]              = "CP1252",
    [wx.wxLANGUAGE_SPANISH_COLOMBIA]           = "CP1252",
    [wx.wxLANGUAGE_SPANISH_COSTA_RICA]         = "CP1252",
    [wx.wxLANGUAGE_SPANISH_DOMINICAN_REPUBLIC] = "CP1252",
    [wx.wxLANGUAGE_SPANISH_ECUADOR]            = "CP1252",
    [wx.wxLANGUAGE_SPANISH_EL_SALVADOR]        = "CP1252",
    [wx.wxLANGUAGE_SPANISH_GUATEMALA]          = "CP1252",
    [wx.wxLANGUAGE_SPANISH_HONDURAS]           = "CP1252",
    [wx.wxLANGUAGE_SPANISH_MEXICAN]            = "CP1252",
    [wx.wxLANGUAGE_SPANISH_MODERN]             = "CP1252",
    [wx.wxLANGUAGE_SPANISH_NICARAGUA]          = "CP1252",
    [wx.wxLANGUAGE_SPANISH_PANAMA]             = "CP1252",
    [wx.wxLANGUAGE_SPANISH_PARAGUAY]           = "CP1252",
    [wx.wxLANGUAGE_SPANISH_PERU]               = "CP1252",
    [wx.wxLANGUAGE_SPANISH_PUERTO_RICO]        = "CP1252",
    [wx.wxLANGUAGE_SPANISH_URUGUAY]            = "CP1252",
    [wx.wxLANGUAGE_SPANISH_US]                 = "CP1252",
    [wx.wxLANGUAGE_SPANISH_VENEZUELA]          = "CP1252",
    [wx.wxLANGUAGE_SWEDISH]                    = "CP1252",
    [wx.wxLANGUAGE_SWEDISH_FINLAND]            = "CP1252",
    [wx.wxLANGUAGE_UKRAINIAN]              = "CP1251",
}

local function AddListItem(row)
    local index = listview:GetItemCount()
    index = listview:InsertItem(index, row[1])
    listview:SetItem(index, 1, tostring(row[2]))
    listview:SetItem(index, 2, tostring(row[3]))
    return index
end

local function FillListView()
    listview:InsertColumn(0, "Lauguage", wx.wxLIST_FORMAT_LEFT, -1)
    listview:InsertColumn(1, "Iconv", wx.wxLIST_FORMAT_LEFT, -1)
    listview:InsertColumn(2, "Encoding", wx.wxLIST_FORMAT_LEFT, -1)

    listview:SetColumnWidth(0, 80)
    listview:SetColumnWidth(1, 0)
    listview:SetColumnWidth(2, 315)

    AddListItem({"Unicode",  "UTF-8",       "UTF-8"})
    AddListItem({"European", "ISO-8859-1",  "ISO-8859-1 / latin1"})
    AddListItem({"European", "ISO-8859-2",  "ISO-8859-2 / latin2"})
    AddListItem({"European", "ISO-8859-3",  "ISO-8859-3 / latin3"})
    AddListItem({"European", "ISO-8859-4",  "ISO-8859-4 / latin4"})
    AddListItem({"European", "ISO-8859-9",  "ISO-8859-9 / latin5"})
    AddListItem({"European", "ISO-8859-10", "ISO-8859-10 / latin6"})
    AddListItem({"European", "ISO-8859-13", "ISO-8859-13 / latin7"})
    AddListItem({"European", "ISO-8859-14", "ISO-8859-14 / latin8"})
    AddListItem({"European", "ISO-8859-15", "ISO-8859-15 / latin9"})
    AddListItem({"European", "ISO-8859-16", "ISO-8859-16 / latin10"})
    AddListItem({"European", "CP1250",      "CP1250 / windows-1250"})
    AddListItem({"European", "CP1251",      "CP1251 / windows-1251"}) -- Cyrillic
    AddListItem({"European", "CP1252",      "CP1252 / windows-1252"})
    AddListItem({"European", "CP1253",      "CP1253 / windows-1253"}) -- Greek
    AddListItem({"European", "CP1257",      "CP1257 / windows-1257"})
    AddListItem({"European", "KOI8-R",      "KOI8-R"}) -- Cyrillic
    AddListItem({"European", "KOI8-U",      "KOI8-U"}) -- Cyrillic
    AddListItem({"Chinese",  "GB18030",     "GB2312 / GBK / GB18030 / CP936 / windows-936"})
    AddListItem({"Chinese",  "BIG5",        "BIG5 / CP950 / windows-950"})
    AddListItem({"Japanese", "SHIFT_JIS",   "SHIFT_JIS / CP932 / windows-932"})
    AddListItem({"Korean",   "EUC-KR",      "EUC-KR / CP949 / windows-949"})
end

local function CreateDialog()
    dialog = wx.wxDialog(frame, wx.wxID_ANY, "Choose File Encoding")

    listview = wx.wxListView(dialog, wx.wxID_ANY,
                        wx.wxDefaultPosition, wx.wxSize(400, 380),
                        wx.wxLC_REPORT + wx.wxLC_SINGLE_SEL + wx.wxLC_HRULES + wx.wxLC_VRULES)
    FillListView(listview)
    listview:Select(0)

    local line = wx.wxStaticLine(dialog, wx.wxID_ANY)
    local button = wx.wxButton(dialog, wx.wxID_OK, "OK")
    local sizer = wx.wxBoxSizer(wx.wxVERTICAL)
    sizer:Add(listview, 1, wx.wxALL, 10)
    sizer:Add(line, 0, wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT, 10)
    sizer:Add(button, 0, wx.wxALL + wx.wxALIGN_RIGHT, 10)

    dialog:SetAutoLayout(true)
    dialog:SetSizer(sizer)
    sizer:Fit(dialog)
end

function encoding:Choose()
    if not dialog then CreateDialog() end
    listview:SetFocus()

    if (dialog:ShowModal() == wx.wxID_OK) then
        local index = listview:GetFirstSelected()
        local item = wx.wxListItem()
        item:SetId(index)
        item:SetColumn(1)
        item:SetMask(wx.wxLIST_MASK_TEXT)
        listview:GetItem(item)
        local enc = item:GetText()
        return enc
    end
end

function encoding:Convert(text, from, to)
    local cd = iconv.open(to, from)
    if cd then
        local output, err = cd:iconv(text)
        if not err then return output end
    end
    return nil
end

function encoding:Detect(text)
    local enc, out
    -- step one
    for _, enc in ipairs(encList) do
        if string.upper(enc) == "SYSTEM" then
           enc = wx.wxLocale.GetSystemEncodingName()
        end
        out = self:Convert(text, enc, "UTF-8")
        if out then return enc, out end
    end
    -- step two
    local lang = wx.wxLocale.GetSystemLanguage()
    enc = lang2enc[lang]
    if enc then
        out = self:Convert(text, enc, "UTF-8")
        if out then return enc, out end
    end
    -- step three
    enc = encoding:Choose()
    if enc then
        out = self:Convert(text, enc, "UTF-8")
        if out then return enc, out end
    end
end
