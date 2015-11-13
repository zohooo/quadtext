
statusbar = frame:CreateStatusBar(4)

local status_txt_width = statusbar:GetTextExtent("OVRW")

frame:SetStatusWidths({-1, status_txt_width, status_txt_width, status_txt_width*5})
frame:SetStatusText("Welcome to QuadText")

-- ----------------------------------------------------------------------------
-- Update the statusbar text of the frame using the given editor.
-- Only update if the text has changed.

local statusTextTable = { "OVR?", "R/O?", "Cursor Pos" }

function statusbar:UpdateStatusText(editor)
    local texts = { "", "", "" }
    if frame and editor then
        local pos  = editor:GetCurrentPos()
        local line = editor:LineFromPosition(pos)
        local col  = 1 + pos - editor:PositionFromLine(line)

        texts = { iff(editor:GetOvertype(), "OVR", "INS"),
                  iff(editor:GetReadOnly(), "R/O", "R/W"),
                  "Ln "..tostring(line + 1).." Col "..tostring(col) }
    end

    if frame then
        for n = 1, 3 do
            if (texts[n] ~= statusTextTable[n]) then
                frame:SetStatusText(texts[n], n)
                statusTextTable[n] = texts[n]
            end
        end
    end
end
