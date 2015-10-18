-- ---------------------------------------------------------------------------
-- Create the Help menu and attach the callback functions

local ID_ABOUT            = wx.wxID_ABOUT

helpMenu = wx.wxMenu{
        { ID_ABOUT,      "&About\tF1",       "About QuadText" }}
menuBar:Append(helpMenu, "&Help")

function DisplayAbout(event)
    local page = [[
        <html>
        <body bgcolor = "#FFFFFF">
        <table cellspacing = 4 cellpadding = 4 width = "100%">
          <tr>
            <td>
              <b><font size=+1 color="#00007E">QuadText Editor ]]..app.version..[[</font></b><br>
              Copyright &copy; 2015 QuadText Project<br>
              Licensed under GNU General Public License, Version 3.
             </td>
          </tr>
          <tr>
            <td>
              <b>Based on wxLua Editor</b><br>
              Copyright &copy; 2002-2005 Lomtick Software<br>
              J. Winwood, John Labenski<br>
              Licensed under wxWindows Library License, Version 3.
            </td>
          </tr>
          <tr>
            <td><b>Build with ]]..wx.wxVERSION_STRING..[[ and ]]..wxlua.wxLUA_VERSION_STRING..[[</b></td>
          </tr>
        </table>
        </body>
        </html>
    ]]

    local dlg = wx.wxDialog(frame, wx.wxID_ANY, "About QuadText")

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
