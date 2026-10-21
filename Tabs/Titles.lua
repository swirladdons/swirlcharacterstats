local SCS = SwirlCharacterStats

function SCS.CreateTitlesPanel(parent)
    local t = SwirlUI and SwirlUI.Theme
    local C = SwirlUI and SwirlUI.Components
    local titlesPanel, titlesScrollFrame, titlesScrollChild =
        SCS.CreatePanelShell(parent, "SCS_TitlesPanel", { withScrollbar = true })

    local titlesSearchBox = CreateFrame("EditBox", "SCS_TitlesSearchBox", titlesPanel)
    titlesSearchBox:SetSize(SCS.panelWidth - 10, 22)
    titlesSearchBox:SetPoint("TOPLEFT", titlesPanel, "TOPLEFT", 5, -30)
    titlesSearchBox:SetAutoFocus(false)
    titlesSearchBox:SetMaxLetters(20)

    local searchBg = titlesSearchBox:CreateTexture(nil, "BACKGROUND")
    searchBg:SetColorTexture(t.bg.med.r, t.bg.med.g, t.bg.med.b, t.bg.med.a)
    searchBg:SetAllPoints()

    SCS.CreateBorder(titlesSearchBox, 0, 0, 0, 1, 1)

    titlesSearchBox:SetTextColor(1, 1, 1, 1)
    titlesSearchBox:SetFont(t.font.path, t.font.size.small, "OUTLINE")
    titlesSearchBox:SetShadowColor(0, 0, 0, 0)
    titlesSearchBox:SetTextInsets(4, 4, 0, 0)

    local hintText = titlesSearchBox:CreateFontString(nil, "OVERLAY")
    hintText:SetFont(t.font.path, t.font.size.small + 2, "OUTLINE")
    hintText:SetShadowColor(0, 0, 0, 0)
    hintText:SetText("Search titles...")
    hintText:SetTextColor(0.6, 0.6, 0.6, 0.7)
    hintText:SetPoint("LEFT", titlesSearchBox, "LEFT", 4, 0)

    local clearHit = C:CreateCloseButton(titlesSearchBox, function()
        titlesSearchBox:SetText("")
        titlesSearchBox:ClearFocus()
    end, { size = 18, normalColor = t.text.muted })
    clearHit:SetPoint("RIGHT", titlesSearchBox, "RIGHT", -2, 0)
    clearHit:Hide()

    local titleButtons = {}
    local selectedTitleIndex = nil

    local TILE_H = 24
    local TILE_GAP = 2
    local TILE_STEP = TILE_H + TILE_GAP
    local ac  = t.accent
    local med = t.bg.med
    local hov = t.bg.hover

    local _titlesBuilt = false

    local function PaintTitleSelection(newIndex)
        local prev = selectedTitleIndex
        selectedTitleIndex = newIndex

        if prev ~= nil then
            local oldData = titleButtons[prev]
            if oldData and oldData.bg then
                oldData.bg:SetColorTexture(med.r, med.g, med.b, med.a)
            end
            local newData = titleButtons[newIndex]
            if newData and newData.bg then
                newData.bg:SetColorTexture(ac.r, ac.g, ac.b, 0.5)
            end
        else
            for idx, btnData in pairs(titleButtons) do
                if idx == newIndex then
                    btnData.bg:SetColorTexture(ac.r, ac.g, ac.b, 0.15)
                else
                    btnData.bg:SetColorTexture(med.r, med.g, med.b, med.a)
                end
            end
        end
    end

    local function _createTitleButton(titleIndex)
        local btn = CreateFrame("Button", nil, titlesScrollChild)
        btn:SetWidth(SCS.panelWidth - 10 - 3)
        btn:SetHeight(TILE_H)

        btn._bg = btn:CreateTexture(nil, "BACKGROUND")
        btn._bg:SetColorTexture(med.r, med.g, med.b, med.a)
        btn._bg:SetAllPoints()

        SCS.CreateBorder(btn, 0, 0, 0, 1, 1)

        btn._hover = btn:CreateTexture(nil, "ARTWORK")
        btn._hover:SetColorTexture(hov.r, hov.g, hov.b, hov.a)
        btn._hover:SetAllPoints()
        btn._hover:Hide()

        btn._text = btn:CreateFontString(nil, "OVERLAY")
        btn._text:SetFont(t.font.path, 11, "OUTLINE")
        btn._text:SetShadowColor(0, 0, 0, 0)
        btn._text:SetTextColor(1, 1, 1, 1)
        btn._text:SetPoint("LEFT", btn, "LEFT", 10, 0)

        btn._titleIndex = titleIndex
        btn:SetScript("OnEnter", function(self) self._hover:Show() end)
        btn:SetScript("OnLeave", function(self) self._hover:Hide() end)
        btn:SetScript("OnClick", function(self)
            SetCurrentTitle(self._titleIndex)
            PaintTitleSelection(self._titleIndex)
        end)

        return btn
    end

    local function BuildTitlesList()
        if _titlesBuilt then return end
        _titlesBuilt = true

        local noTitleBtn = _createTitleButton(-1)
        noTitleBtn._text:SetText("No Title")
        titleButtons[-1] = { btn = noTitleBtn, bg = noTitleBtn._bg }

        for titleIndex = 1, GetNumTitles() do
            if IsTitleKnown(titleIndex) then
                local titleName = GetTitleName(titleIndex)
                if titleName then
                    local btn = _createTitleButton(titleIndex)
                    btn._titleName = titleName
                    btn._text:SetText(titleName)
                    titleButtons[titleIndex] = { btn = btn, bg = btn._bg }
                end
            end
        end
    end

    local function FilterTitlesList()
        BuildTitlesList()

        local searchText = (titlesSearchBox:GetText() or ""):lower()
        local yOffset = 0

        local ordered = {}
        for idx in pairs(titleButtons) do ordered[#ordered + 1] = idx end
        table.sort(ordered)

        for _, idx in ipairs(ordered) do
            local btnData = titleButtons[idx]
            local btn = btnData.btn
            local name = (idx == -1) and "No Title" or (btn._titleName or "")
            local visible = (searchText == "")
                or (idx == -1)
                or name:lower():find(searchText, 1, true)

            if visible then
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", titlesScrollChild, "TOPLEFT", 5, yOffset)
                btn:Show()
                yOffset = yOffset - TILE_STEP
            else
                btn:Hide()
            end
        end

        PaintTitleSelection(GetCurrentTitle())
        titlesScrollChild:SetHeight(-yOffset)
        titlesScrollFrame:SetVerticalScroll(0)
    end

    local titlesInvalidator = CreateFrame("Frame")
    titlesInvalidator:RegisterEvent("KNOWN_TITLES_UPDATE")
    titlesInvalidator:SetScript("OnEvent", function()
        _titlesBuilt = false
        for idx, data in pairs(titleButtons) do
            if data.btn then data.btn:Hide() end
            titleButtons[idx] = nil
        end
    end)

    titlesSearchBox:SetScript("OnTextChanged", function(self)
        if (self:GetText() or "") ~= "" then
            clearHit:Show()
        else
            clearHit:Hide()
        end
        FilterTitlesList()
    end)

    titlesSearchBox:SetScript("OnEditFocusGained", function()
        if titlesSearchBox:GetText() == "" then
            hintText:Hide()
        end
    end)

    titlesSearchBox:SetScript("OnEditFocusLost", function()
        if titlesSearchBox:GetText() == "" then
            hintText:Show()
        end
    end)

    titlesSearchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    FilterTitlesList()

    titlesPanel:HookScript("OnShow", function()
        titlesSearchBox:SetText("")
        FilterTitlesList()
    end)

    return titlesPanel
end
