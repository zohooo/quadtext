-- ---------------------------------------------------------------------------
-- Create the Help menu and attach the callback functions

local ID_ABOUT            = wx.wxID_ABOUT

helpMenu = wx.wxMenu{
        { ID_ABOUT,      "&About\tF1",       "About wxLua IDE" }}
menuBar:Append(helpMenu, "&Help")

function DisplayAbout(event)
    local page = [[
        <html>
        <body bgcolor = "#FFFFFF">
        <table cellspacing = 4 cellpadding = 4 width = "100%">
          <tr>
            <td bgcolor = "#202020">
            <center>
                <font size = +2 color = "#FFFFFF"><br><b>]]..
                    wxlua.wxLUA_VERSION_STRING..[[</b></font><br>
                <font size = +1 color = "#FFFFFF">built with</font><br>
                <font size = +2 color = "#FFFFFF"><b>]]..
                    wx.wxVERSION_STRING..[[</b></font>
            </center>
            </td>
          </tr>
          <tr>
            <td bgcolor = "#DCDCDC">
            <b>Copyright (C) 2002-2005 Lomtick Software</b>
            <p>
            <font size=-1>
              <table cellpadding = 0 cellspacing = 0 width = "100%">
                <tr>
                  <td width = "65%">
                    J. Winwood (luascript@thersgb.net)<br>
                    John Labenski<p>
                  </td>
                  <td valign = top>
                    <img src = "memory:wxLua">
                  </td>
                </tr>
              </table>
            <font size = 1>
                Licenced under wxWindows Library Licence, Version 3.
            </font>
            </font>
            </td>
          </tr>
        </table>
        </body>
        </html>
    ]]

    local dlg = wx.wxDialog(frame, wx.wxID_ANY, "About wxLua IDE")

    local html = wx.wxLuaHtmlWindow(dlg, wx.wxID_ANY,
                                    wx.wxDefaultPosition, wx.wxSize(360, 150),
                                    wx.wxHW_SCROLLBAR_NEVER)
    local line = wx.wxStaticLine(dlg, wx.wxID_ANY)
    local button = wx.wxButton(dlg, wx.wxID_OK, "OK")

    button:SetDefault()

    html:SetBorders(0)
    html:SetPage(page)
    html:SetSize(html:GetInternalRepresentation():GetWidth(),
                 html:GetInternalRepresentation():GetHeight())

    local topsizer = wx.wxBoxSizer(wx.wxVERTICAL)
    topsizer:Add(html, 1, wx.wxALL, 10)
    topsizer:Add(line, 0, wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT, 10)
    topsizer:Add(button, 0, wx.wxALL + wx.wxALIGN_RIGHT, 10)

    dlg:SetAutoLayout(true)
    dlg:SetSizer(topsizer)
    topsizer:Fit(dlg)

    dlg:ShowModal()
    dlg:Destroy()
end

frame:Connect(ID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, DisplayAbout)
