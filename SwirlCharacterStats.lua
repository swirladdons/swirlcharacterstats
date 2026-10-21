SwirlCharacterStats = SwirlCharacterStats or {}
local SCS = SwirlCharacterStats

SCS.panelWidth = 198

local function MakeColor(r, g, b, a)
    return { r = r, g = g, b = b, a = a or 1 }
end

local FALLBACK_THEME = (function()
    local _, class = UnitClass("player")
    local cc = class and RAID_CLASS_COLORS[class]
    local ar, ag, ab = cc and cc.r or 0.047, cc and cc.g or 0.824, cc and cc.b or 0.616
    return {
        bg = {
            dark  = MakeColor(0.024, 0.031, 0.031, 0.65),
            med   = MakeColor(0.102, 0.102, 0.098, 0.9),
            hover = MakeColor(1, 1, 1, 0.15),
        },
        accent = MakeColor(ar, ag, ab),
        font = {
            path = STANDARD_TEXT_FONT,
            size = { large = 18, normal = 12, small = 10 },
        },
    }
end)()

local function T()
    return (SwirlUI and SwirlUI.Theme) or FALLBACK_THEME
end

function SCS.CreateBorder(frame, r, g, b, a, thickness)
    r = r or 0
    g = g or 0
    b = b or 0
    a = a or 1
    thickness = thickness or 1

    local topBorder = CreateFrame("Frame", nil, frame)
    topBorder:SetHeight(thickness)
    topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topBorder:SetFrameLevel(frame:GetFrameLevel() + 10)
    local topTex = topBorder:CreateTexture(nil, "BACKGROUND")
    topTex:SetColorTexture(r, g, b, a)
    topTex:SetAllPoints()

    local bottomBorder = CreateFrame("Frame", nil, frame)
    bottomBorder:SetHeight(thickness)
    bottomBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottomBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottomBorder:SetFrameLevel(frame:GetFrameLevel() + 10)
    local bottomTex = bottomBorder:CreateTexture(nil, "BACKGROUND")
    bottomTex:SetColorTexture(r, g, b, a)
    bottomTex:SetAllPoints()

    local leftBorder = CreateFrame("Frame", nil, frame)
    leftBorder:SetWidth(thickness)
    leftBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    leftBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    leftBorder:SetFrameLevel(frame:GetFrameLevel() + 10)
    local leftTex = leftBorder:CreateTexture(nil, "BACKGROUND")
    leftTex:SetColorTexture(r, g, b, a)
    leftTex:SetAllPoints()

    local rightBorder = CreateFrame("Frame", nil, frame)
    rightBorder:SetWidth(thickness)
    rightBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    rightBorder:SetFrameLevel(frame:GetFrameLevel() + 10)
    local rightTex = rightBorder:CreateTexture(nil, "BACKGROUND")
    rightTex:SetColorTexture(r, g, b, a)
    rightTex:SetAllPoints()

    frame.border = {
        top = topBorder,
        bottom = bottomBorder,
        left = leftBorder,
        right = rightBorder,
    }
end

function SCS.AttachCustomScrollbar(scrollFrame, scrollChild, opts)
    opts = opts or {}
    local trackOwner = opts.trackOwner or scrollFrame
    local topInset = opts.topInset or 0
    local bottomInset = opts.bottomInset or 0

    local track = CreateFrame("Frame", nil, trackOwner)
    track:SetWidth(3)
    track:SetPoint("TOPRIGHT", trackOwner, "TOPRIGHT", 0, topInset)
    track:SetPoint("BOTTOMRIGHT", trackOwner, "BOTTOMRIGHT", 0, bottomInset)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    local t = T()
    trackBg:SetColorTexture(t.bg.med.r, t.bg.med.g, t.bg.med.b, t.bg.med.a)
    trackBg:SetAllPoints()

    local function CreateTrackBorder(frame)
        local top = frame:CreateTexture(nil, "BORDER")
        top:SetColorTexture(0, 0, 0, 1)
        top:SetHeight(1)
        top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        local bottom = frame:CreateTexture(nil, "BORDER")
        bottom:SetColorTexture(0, 0, 0, 1)
        bottom:SetHeight(1)
        bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        local left = frame:CreateTexture(nil, "BORDER")
        left:SetColorTexture(0, 0, 0, 1)
        left:SetWidth(1)
        left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        local right = frame:CreateTexture(nil, "BORDER")
        right:SetColorTexture(0, 0, 0, 1)
        right:SetWidth(1)
        right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    end
    CreateTrackBorder(track)

    local thumb = CreateFrame("Frame", nil, track)
    thumb:SetWidth(3)
    thumb:SetHeight(40)

    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    local ac = T().accent
    thumbTex:SetColorTexture(ac.r, ac.g, ac.b, 0.8)
    thumbTex:SetAllPoints()

    local function CreateThumbBorder(frame)
        local top = frame:CreateTexture(nil, "OVERLAY", nil, 1)
        top:SetColorTexture(0, 0, 0, 1)
        top:SetHeight(1)
        top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        local bottom = frame:CreateTexture(nil, "OVERLAY", nil, 1)
        bottom:SetColorTexture(0, 0, 0, 1)
        bottom:SetHeight(1)
        bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        local left = frame:CreateTexture(nil, "OVERLAY", nil, 1)
        left:SetColorTexture(0, 0, 0, 1)
        left:SetWidth(1)
        left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        local right = frame:CreateTexture(nil, "OVERLAY", nil, 1)
        right:SetColorTexture(0, 0, 0, 1)
        right:SetWidth(1)
        right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    end
    CreateThumbBorder(thumb)

    local function UpdateThumb()
        local scrollRange = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if scrollRange <= 0 then
            thumb:Hide()
            return
        end

        thumb:Show()
        local trackHeight = track:GetHeight()
        local ratio = scrollFrame:GetHeight() / scrollChild:GetHeight()
        local thumbHeight = math.max(20, trackHeight * ratio)
        thumb:SetHeight(thumbHeight)

        local scrollPos = scrollFrame:GetVerticalScroll()
        local thumbPos = (scrollPos / scrollRange) * (trackHeight - thumbHeight)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -thumbPos)
    end

    scrollFrame:HookScript("OnScrollRangeChanged", UpdateThumb)
    scrollFrame:HookScript("OnVerticalScroll", UpdateThumb)
    scrollFrame:SetScript("OnSizeChanged", UpdateThumb)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentScroll = self:GetVerticalScroll()
        local scrollRange = scrollChild:GetHeight() - self:GetHeight()
        local newScroll = currentScroll - delta * 20
        newScroll = math.max(0, math.min(newScroll, scrollRange))
        self:SetVerticalScroll(newScroll)
    end)

    thumb:EnableMouse(true)
    thumb:SetScript("OnMouseDown", function(self)
        self.isDragging = true
        self.dragStartY = select(2, GetCursorPosition())
        self.scrollStartY = scrollFrame:GetVerticalScroll()
    end)

    thumb:SetScript("OnMouseUp", function(self)
        self.isDragging = false
    end)

    thumb:SetScript("OnUpdate", function(self)
        if self.isDragging then
            local currentY = select(2, GetCursorPosition())
            local deltaY = self.dragStartY - currentY
            local trackHeight = track:GetHeight()
            local scrollRange = scrollChild:GetHeight() - scrollFrame:GetHeight()
            local thumbHeight = thumb:GetHeight()
            local scrollDelta = (deltaY / (trackHeight - thumbHeight)) * scrollRange
            local newScroll = self.scrollStartY + scrollDelta
            newScroll = math.max(0, math.min(newScroll, scrollRange))
            scrollFrame:SetVerticalScroll(newScroll)
        end
    end)

    C_Timer.After(0.1, UpdateThumb)
end

function SCS.CreateButtonRow(parent, defs, opts)
    opts = opts or {}
    local t = T()
    local totalWidth = opts.width or SCS.panelWidth
    local btnHeight  = opts.height or 25
    local font = opts.font or t.font.path
    local fontSize = opts.fontSize or t.font.size.small + 2
    local count = #defs
    local btnWidth = totalWidth / count

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(totalWidth, btnHeight)
    SCS.CreateBorder(container, 0, 0, 0, 1, 1)

    local ac  = t.accent
    local med = t.bg.med
    local hov = t.bg.hover
    local buttons = {}

    local function paintBtn(btn)
        if btn._active then
            btn._text:SetTextColor(ac.r, ac.g, ac.b, 1)
            btn._bg:SetColorTexture(hov.r, hov.g, hov.b, hov.a)
        elseif btn._hover then
            btn._text:SetTextColor(1, 1, 1, 1)
            btn._bg:SetColorTexture(hov.r, hov.g, hov.b, hov.a)
        else
            btn._text:SetTextColor(1, 1, 1, 0.6)
            btn._bg:SetColorTexture(med.r, med.g, med.b, med.a)
        end
    end

    local function setActive(activeBtn)
        for _, b in ipairs(buttons) do
            b._active = (b == activeBtn)
            paintBtn(b)
        end
    end

    for i, def in ipairs(defs) do
        local btn = CreateFrame("Button", nil, container)
        btn:SetSize(btnWidth, btnHeight)
        btn:SetFrameLevel(container:GetFrameLevel() + 1)

        if i == 1 then
            btn:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        else
            btn:SetPoint("TOPLEFT", buttons[i - 1], "TOPRIGHT", 0, 0)
        end

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        btn._bg = bg

        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(font, fontSize, "OUTLINE")
        text:SetShadowColor(0, 0, 0, 0)
        text:SetPoint("CENTER", btn, "CENTER", 0, 0.5)
        text:SetText(def.label)
        btn._text = text

        btn._active = false
        btn._hover  = false
        paintBtn(btn)

        btn:SetScript("OnEnter", function() btn._hover = true;  paintBtn(btn) end)
        btn:SetScript("OnLeave", function() btn._hover = false; paintBtn(btn) end)
        btn:SetScript("OnClick", function(self, ...)
            if opts.stateful ~= false then setActive(btn) end
            if def.onClick then def.onClick(self, ...) end
        end)

        if i > 1 then
            local div = btn:CreateTexture(nil, "BORDER")
            div:SetColorTexture(0, 0, 0, 1)
            div:SetWidth(1)
            div:SetPoint("TOPLEFT",    btn, "TOPLEFT",    0, 0)
            div:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        end

        buttons[i] = btn
    end

    container.setActive = function(idx) setActive(buttons[idx]) end
    container.buttons = buttons

    return container, buttons
end

function SCS.CreatePanelShell(parent, frameName, opts)
    opts = opts or {}

    local panel = CreateFrame("Frame", frameName, parent)
    panel:SetWidth(SCS.panelWidth)
    panel:Hide()

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    local t = T()
    bg:SetColorTexture(t.bg.dark.r, t.bg.dark.g, t.bg.dark.b, t.bg.dark.a)
    bg:SetAllPoints()
    SCS.CreateBorder(panel, 0, 0, 0, 1, 1)

    local SCROLL_Y = -58

    local scrollFrame = CreateFrame("ScrollFrame", frameName and (frameName .. "_Scroll"), panel)
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, SCROLL_Y)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 1)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetClipsChildren(true)

    local scrollChild = CreateFrame("Frame", frameName and (frameName .. "_ScrollChild"), scrollFrame)
    scrollChild:SetWidth(SCS.panelWidth)
    scrollFrame:SetScrollChild(scrollChild)

    if opts.withScrollbar then
        SCS.AttachCustomScrollbar(scrollFrame, scrollChild, {
            trackOwner = panel,
            topInset = SCROLL_Y,
            bottomInset = 1,
        })
    else
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local cur  = self:GetVerticalScroll()
            local maxS = math.max(0, scrollChild:GetHeight() - self:GetHeight())
            self:SetVerticalScroll(math.max(0, math.min(cur - delta * 20, maxS)))
        end)
    end

    return panel, scrollFrame, scrollChild
end

local function HideBlizzardPanels()
    for _, name in ipairs({"CharacterStatsPane", "CharacterStatPane"}) do
        local blizzPanel = _G[name]
        if blizzPanel then
            blizzPanel:SetParent(nil)
            blizzPanel:Hide()
            blizzPanel:SetAlpha(0)
        end
    end

    for i = 1, 10 do
        local sidebarTab = _G["PaperDollSidebarTab" .. i]
        if sidebarTab then
            sidebarTab:Hide()
            sidebarTab:SetAlpha(0)
        end
    end
end

local function SetupCharacterFrameStats()
    if not CharacterFrame then return end

    HideBlizzardPanels()

    local frame = CharacterFrame

    local statsPanel = SCS.CreateStatsPanel(frame)
    statsPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 335, -62)
    statsPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 335, 38)
    statsPanel:SetFrameLevel(50)
    frame._scsStatsPanel = statsPanel

    local titlesPanel = SCS.CreateTitlesPanel(frame)
    titlesPanel:SetPoint("TOPLEFT", statsPanel, "TOPLEFT", 0, 0)
    titlesPanel:SetPoint("BOTTOMLEFT", statsPanel, "BOTTOMLEFT", 0, 0)
    titlesPanel:SetFrameLevel(50)
    frame._scsTitlesPanel = titlesPanel

    local equipPanel = SCS.CreateEquipmentPanel(frame)
    equipPanel:SetPoint("TOPLEFT", statsPanel, "TOPLEFT", 0, 0)
    equipPanel:SetPoint("BOTTOMLEFT", statsPanel, "BOTTOMLEFT", 0, 0)
    equipPanel:SetFrameLevel(50)
    frame._scsEquipPanel = equipPanel

    local tabContainer = SCS.CreateButtonRow(frame, {
        {
            label = "Character",
            onClick = function()
                frame._scsStatsPanel:Show()
                frame._scsTitlesPanel:Hide()
                frame._scsEquipPanel:Hide()
            end,
        },
        {
            label = "Titles",
            onClick = function()
                frame._scsTitlesPanel:Show()
                frame._scsStatsPanel:Hide()
                frame._scsEquipPanel:Hide()
            end,
        },
        {
            label = "Equipment",
            onClick = function()
                frame._scsEquipPanel:Show()
                frame._scsStatsPanel:Hide()
                frame._scsTitlesPanel:Hide()
            end,
        },
    }, { width = SCS.panelWidth, height = 25 })

    tabContainer:SetPoint("TOPLEFT", statsPanel, "TOPLEFT", 0, 0)
    tabContainer:SetFrameLevel(statsPanel:GetFrameLevel() + 2)

    tabContainer.setActive(1)

    local PaperDollFrame = _G["PaperDollFrame"]
    if PaperDollFrame then
        PaperDollFrame:HookScript("OnShow", function()
            if frame._scsStatsPanel   then frame._scsStatsPanel:Show()   end
            if frame._scsTitlesPanel  then frame._scsTitlesPanel:Hide()  end
            if frame._scsEquipPanel   then frame._scsEquipPanel:Hide()   end
            tabContainer:Show()
            tabContainer.setActive(1)
        end)

        PaperDollFrame:HookScript("OnHide", function()
            if frame._scsStatsPanel   then frame._scsStatsPanel:Hide()   end
            if frame._scsTitlesPanel  then frame._scsTitlesPanel:Hide()  end
            if frame._scsEquipPanel   then frame._scsEquipPanel:Hide()   end
            tabContainer:Hide()
        end)
    end
end

local function CreateSettings(content)
    local sui = SwirlUI
    local C = sui.Components

    local tab = C:CreateTabScroller(content)
    local card = C:CreateCard(tab, "Character Stats")

    card:AddEnableToggle("Enable", SwirlCharacterStatsDB.enabled, function(val)
        SwirlCharacterStatsDB.enabled = val
        sui.SettingsChanged = true
    end)

    tab:AddCard(card)
    tab:Commit()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
local hasSetup = false
initFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "SwirlCharacterStats" then
        if not SwirlCharacterStatsDB then
            SwirlCharacterStatsDB = { enabled = true }
        end
        if SwirlCharacterStatsDB.enabled == nil then
            SwirlCharacterStatsDB.enabled = true
        end

        if SwirlUI_AddTab then
            local built = false
            SwirlUI_AddTab("CharacterStats", "Character Stats", function(content)
                if built then return end
                built = true
                CreateSettings(content)
            end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" and not hasSetup then
        hasSetup = true
        if SwirlCharacterStatsDB.enabled then
            C_Timer.After(0.5, SetupCharacterFrameStats)
        end
    end
end)