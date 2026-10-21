local SCS = SwirlCharacterStats

local function SCS_EquipSet(setID)
    if not setID then return end
    if EquipmentManager_EquipSet then
        EquipmentManager_EquipSet(setID)
    else
        C_EquipmentSet.UseEquipmentSet(setID)
    end
end

local activeEquipmentSetID = nil

local function IsEquipmentSetComplete(setName)
    local setID = C_EquipmentSet.GetEquipmentSetID(setName)
    if not setID then return true end
    local _, _, _, _, _, _, _, numLost = C_EquipmentSet.GetEquipmentSetInfo(setID)
    return (numLost or 0) == 0
end

local function GetMissingSetItems(setName)
    local setID = C_EquipmentSet.GetEquipmentSetID(setName)
    if not setID then return {} end

    local setItems = C_EquipmentSet.GetItemIDs(setID)
    if not setItems then return {} end

    local missing = {}
    local slotNames = {
        "Head", "Neck", "Shoulder", "Back",
        "Chest", "Waist", "Legs", "Feet",
        "Wrist", "Hands", "Finger 1", "Finger 2",
        "Trinket 1", "Trinket 2", "Main Hand", "Off Hand",
        "Tabard", "Chest (Relic)", "Back (Relic)"
    }

    for slot, setItemID in pairs(setItems) do
        if setItemID and setItemID ~= 0 then
            local equippedID = GetInventoryItemID("player", slot)
            if equippedID ~= setItemID then
                local count = C_Item.GetItemCount(setItemID, true, true) or 0
                if count == 0 then
                    local itemName = (C_Item.GetItemInfo and C_Item.GetItemInfo(setItemID))
                        or "Unknown Item"
                    table.insert(missing, {
                        slot = slotNames[slot] or "Unknown",
                        itemID = setItemID,
                        itemName = itemName,
                    })
                end
            end
        end
    end

    return missing
end

function SCS.CreateEquipmentPanel(parent)
    local t = SwirlUI and SwirlUI.Theme
    local C = SwirlUI and SwirlUI.Components
    local ac = t.accent
    local med = t.bg.med
    local hov = t.bg.hover
    local equipPanel, _, equipScrollChild =
        SCS.CreatePanelShell(parent, "SCS_EquipPanel", { withScrollbar = false })

    local selectedSetID = nil
    local setTilePool = {}

    local RefreshEquipmentSets

    local actionBtns, actionRow
    actionRow, actionBtns = SCS.CreateButtonRow(equipPanel, {
        {
            label = "New",
            onClick = function()
                if InCombatLockdown() then return end
                StaticPopupDialogs["SCS_NEW_EQUIPMENT_SET"] = {
                    text = "New equipment set name:",
                    button1 = "Create",
                    button2 = "Cancel",
                    OnAccept = function(dialog)
                        local newName = dialog.EditBox:GetText()
                        if newName ~= "" then
                            C_EquipmentSet.CreateEquipmentSet(newName)
                            RefreshEquipmentSets()
                        end
                    end,
                    hasEditBox = true,
                    editBoxWidth = 350,
                    timeout = 0,
                    whileDead = false,
                    hideOnEscape = true,
                }
                StaticPopup_Show("SCS_NEW_EQUIPMENT_SET")
            end,
        },
        {
            label = "Equip",
            onClick = function()
                if InCombatLockdown() then return end
                local text = actionBtns[2]._text
                text:SetText("Equipped!")
                text:SetTextColor(t.accent.r, t.accent.g, t.accent.b, 1)
                if selectedSetID then
                    SCS_EquipSet(selectedSetID)
                    activeEquipmentSetID = selectedSetID
                    RefreshEquipmentSets()
                end
                C_Timer.After(1, function()
                    if text then
                        text:SetText("Equip")
                        text:SetTextColor(1, 1, 1, 0.6)
                    end
                end)
            end,
        },
        {
            label = "Save",
            onClick = function()
                if InCombatLockdown() then return end
                local text = actionBtns[3]._text
                text:SetText("Saved!")
                text:SetTextColor(t.accent.r, t.accent.g, t.accent.b, 1)
                if selectedSetID then
                    C_EquipmentSet.SaveEquipmentSet(selectedSetID)
                end
                C_Timer.After(1, function()
                    if text then
                        text:SetText("Save")
                        text:SetTextColor(1, 1, 1, 0.6)
                    end
                end)
            end,
        },
    }, { width = SCS.panelWidth - 10, height = 22, stateful = false })

    actionRow:SetPoint("TOPLEFT", equipPanel, "TOPLEFT", 5, -30)

    local TILE_H = 24
    local TILE_GAP = 2
    local TILE_STEP = TILE_H + TILE_GAP

    RefreshEquipmentSets = function()
        local equipmentSets = {}
        local setIDs = C_EquipmentSet.GetEquipmentSetIDs()
        if setIDs then
            for _, setID in ipairs(setIDs) do
                local setName, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)
                if setName and setName ~= "" then
                    local assignedSpec = C_EquipmentSet.GetEquipmentSetAssignedSpec(setID)
                    table.insert(equipmentSets, { id = setID, name = setName, spec = assignedSpec, equipped = isEquipped })
                end
            end
        end

        -- sort by spec, then by name matching blizz sorting
        table.sort(equipmentSets, function(a, b)
            if a.spec and b.spec then return a.spec < b.spec end
            if a.spec then return true end
            if b.spec then return false end
            return a.name:lower() < b.name:lower()
        end)

        activeEquipmentSetID = nil
        for _, setData in ipairs(equipmentSets) do
            if setData.equipped then
                activeEquipmentSetID = setData.id
                break
            end
        end

        if not selectedSetID and activeEquipmentSetID then
            selectedSetID = activeEquipmentSetID
        end

        local function _acquireTile(index)
            local tile = setTilePool[index]
            if tile then return tile end

            tile = CreateFrame("Button", nil, equipScrollChild)
            tile:SetWidth(SCS.panelWidth - 10)
            tile:SetHeight(TILE_H)
            tile:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            tile._bg = tile:CreateTexture(nil, "BACKGROUND")
            tile._bg:SetAllPoints()

            SCS.CreateBorder(tile, 0, 0, 0, 1, 1)

            tile._selection = tile:CreateTexture(nil, "ARTWORK", nil, -1)
            tile._selection:SetAllPoints()
            tile._selection:Hide()

            tile._hover = tile:CreateTexture(nil, "ARTWORK")
            tile._hover:SetColorTexture(hov.r, hov.g, hov.b, hov.a)
            tile._hover:SetAllPoints()
            tile._hover:Hide()

            local setIconFrame = CreateFrame("Frame", nil, tile)
            setIconFrame:SetSize(TILE_H, TILE_H)
            setIconFrame:SetPoint("LEFT", tile, "LEFT", 0, 0)
            SCS.CreateBorder(setIconFrame, 0, 0, 0, 1, 1)

            tile._setIcon = setIconFrame:CreateTexture(nil, "ARTWORK")
            tile._setIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            tile._setIcon:SetAllPoints(setIconFrame)
            tile._setIconFrame = setIconFrame

            tile._text = tile:CreateFontString(nil, "OVERLAY")
            tile._text:SetFont(t.font.path, t.font.size.small + 2, "OUTLINE")
            tile._text:SetShadowColor(0, 0, 0, 0)
            tile._text:SetPoint("LEFT", tile._setIcon, "RIGHT", 6, 0)

            -- spec frame anchored to tile RIGHT; cog/del chain left from it
            local specIconFrame = CreateFrame("Frame", nil, tile)
            specIconFrame:SetSize(TILE_H, TILE_H)
            specIconFrame:SetPoint("RIGHT", tile, "RIGHT", -1, 0)
            SCS.CreateBorder(specIconFrame, 0, 0, 0, 1, 1)

            tile._specIcon = specIconFrame:CreateTexture(nil, "ARTWORK")
            tile._specIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            tile._specIcon:SetAllPoints(specIconFrame)
            tile._specIconFrame = specIconFrame
            specIconFrame:Hide()

            local del = C:CreateCloseButton(tile, nil, { size = TILE_H, normalColor = t.text.muted })
            del:SetPoint("RIGHT", specIconFrame, "LEFT", 0, 0)
            del:SetAlpha(0)
            local _delEnter = del:GetScript("OnEnter")
            local _delLeave = del:GetScript("OnLeave")
            del:SetScript("OnEnter", function(self)
                _delEnter(self)
                tile._hover:Show()
                tile._cog:SetAlpha(1)
                tile._del:SetAlpha(1)
            end)
            del:SetScript("OnLeave", function(self)
                _delLeave(self)
                if not tile:IsMouseOver() then
                    tile._hover:Hide()
                    tile._cog:SetAlpha(0)
                    tile._del:SetAlpha(0)
                end
            end)
            del:SetScript("OnClick", function()
                local sid, sname = tile._setID, tile._setName
                if not (sid and sname) then return end
                StaticPopupDialogs["SCS_DELETE_EQUIPMENT_SET"] = {
                    text = "Delete equipment set '" .. sname .. "'?",
                    button1 = "Delete",
                    button2 = "Cancel",
                    OnAccept = function()
                        C_EquipmentSet.DeleteEquipmentSet(sid)
                        RefreshEquipmentSets()
                    end,
                    timeout = 0,
                    whileDead = false,
                    hideOnEscape = true,
                }
                StaticPopup_Show("SCS_DELETE_EQUIPMENT_SET")
            end)
            tile._del = del

            local cog = C:CreateIconButton(tile, {
                size = TILE_H / 2,
                texture = "Interface\\AddOns\\SwirlCharacterStats\\Media\\Cogwheel.png",
                normalColor = t.text.muted,
                hoverColor = t.accent,
            })
            cog:SetPoint("RIGHT", del, "LEFT", 0, 0)
            cog:SetAlpha(0)
            local _cogEnter = cog:GetScript("OnEnter")
            local _cogLeave = cog:GetScript("OnLeave")
            cog:SetScript("OnEnter", function(self)
                _cogEnter(self)
                tile._hover:Show()
                tile._cog:SetAlpha(1)
                tile._del:SetAlpha(1)
            end)
            cog:SetScript("OnLeave", function(self)
                _cogLeave(self)
                if not tile:IsMouseOver() then
                    tile._hover:Hide()
                    tile._cog:SetAlpha(0)
                    tile._del:SetAlpha(0)
                end
            end)
            tile._cog = cog

            local function OpenCogMenu()
                local sid = tile._setID
                if not sid then return end

                local items = {
                    {
                        text = "Change Icon",
                        onClick = function()
                            if InCombatLockdown() then return end
                            local pickSid = tile._setID
                            local pickSname = tile._setName
                            if not (pickSid and pickSname) then return end
                            StaticPopupDialogs["SCS_EQUIP_SET_ICON"] = {
                                text = "Icon file ID for '" .. pickSname .. "':",
                                button1 = "Set",
                                button2 = "Cancel",
                                hasEditBox = true,
                                editBoxWidth = 200,
                                timeout = 0,
                                whileDead = false,
                                hideOnEscape = true,
                                OnShow = function(dialog)
                                    local eb = dialog.EditBox or dialog.editBox
                                    if eb then
                                        local _, curIcon = C_EquipmentSet.GetEquipmentSetInfo(pickSid)
                                        eb:SetText(tostring(curIcon or ""))
                                        eb:HighlightText()
                                    end
                                end,
                                OnAccept = function(dialog)
                                    local eb = dialog.EditBox or dialog.editBox
                                    local iconID = tonumber(eb and eb:GetText() or "")
                                    if iconID then
                                        C_EquipmentSet.ModifyEquipmentSet(pickSid, pickSname, iconID)
                                        RefreshEquipmentSets()
                                    end
                                end,
                            }
                            StaticPopup_Show("SCS_EQUIP_SET_ICON")
                        end,
                    },
                    {
                        text = "Unassigned",
                        onClick = function()
                            if InCombatLockdown() then return end
                            C_EquipmentSet.UnassignEquipmentSetSpec(sid)
                            RefreshEquipmentSets()
                        end,
                    },
                }

                for i = 1, GetNumSpecializations() do
                    local id, specName = GetSpecializationInfo(i)
                    if id then
                        local specIdx = i
                        items[#items + 1] = {
                            text = specName,
                            onClick = function()
                                if InCombatLockdown() then return end
                                C_EquipmentSet.AssignSpecToEquipmentSet(sid, specIdx)
                                RefreshEquipmentSets()
                            end,
                        }
                    end
                end

                local menu = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")
                UIDropDownMenu_Initialize(menu, function()
                    for _, item in ipairs(items) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = item.text
                        info.func = item.onClick
                        info.notCheckable = true
                        UIDropDownMenu_AddButton(info)
                    end
                end, "MENU")
                ToggleDropDownMenu(1, nil, menu, cog, 0, 0)
            end

            tile._OpenCogMenu = OpenCogMenu
            cog:SetScript("OnClick", function() OpenCogMenu() end)

            tile:RegisterForDrag("LeftButton")
            tile:SetScript("OnDragStart", function()
                if tile._setID and C_EquipmentSet.PickupEquipmentSet then
                    C_EquipmentSet.PickupEquipmentSet(tile._setID)
                end
            end)

            tile._lastClick = 0
            tile:SetScript("OnClick", function(_, button)
                local sid = tile._setID
                if not sid then return end

                if button == "RightButton" then
                    if tile._OpenCogMenu then
                        tile._OpenCogMenu()
                    end
                    return
                end

                selectedSetID = sid
                local now = GetTime()
                if (now - (tile._lastClick or 0)) < 0.4 then
                    tile._lastClick = 0
                    if not InCombatLockdown() then
                        SCS_EquipSet(sid)
                        activeEquipmentSetID = sid
                    end
                else
                    tile._lastClick = now
                end
                RefreshEquipmentSets()
            end)

            tile:SetScript("OnEnter", function()
                tile._hover:Show()
                tile._cog:SetAlpha(1)
                tile._del:SetAlpha(1)
                if not IsEquipmentSetComplete(tile._setName) then
                    local missing = GetMissingSetItems(tile._setName)
                    if #missing > 0 then
                        GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
                        GameTooltip:AddLine("Missing Items:", 1, 0.3, 0.3, true)
                        for _, item in ipairs(missing) do
                            local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(item.itemID))
                                or (GetItemIcon and GetItemIcon(item.itemID))
                            local iconText = icon and string.format("|T%s:16|t", icon) or ""
                            GameTooltip:AddLine(
                                string.format("%s %s: %s", iconText, item.slot, item.itemName),
                                1, 1, 1, true)
                        end
                        GameTooltip:Show()
                    end
                end
            end)

            tile:SetScript("OnLeave", function()
                if tile._cog:IsMouseOver() or tile._del:IsMouseOver() then return end
                GameTooltip:Hide()
                tile._hover:Hide()
                tile._cog:SetAlpha(0)
                tile._del:SetAlpha(0)
            end)

            tile._setText = tile._text

            setTilePool[index] = tile
            return tile
        end

        local yOffset = 0
        for i, setData in ipairs(equipmentSets) do
            local tile = _acquireTile(i)

            tile._setID = setData.id
            tile._setName = setData.name

            local _, setIconID = C_EquipmentSet.GetEquipmentSetInfo(setData.id)
            if setIconID then
                tile._setIcon:SetTexture(setIconID)
            end

            tile._text:SetText(setData.name)
            if IsEquipmentSetComplete(setData.name) then
                tile._text:SetTextColor(1, 1, 1, 1)
            else
                tile._text:SetTextColor(1, 0.3, 0.3, 1)
            end

            tile._bg:SetColorTexture(med.r, med.g, med.b, med.a)

            if tile._selection then
                if selectedSetID == setData.id then
                    tile._selection:SetColorTexture(ac.r, ac.g, ac.b, 0.15)
                    tile._selection:Show()
                else
                    tile._selection:Hide()
                end
            end

            if tile.border then
                local isEquipped = setData.equipped
                for _, borderFrame in pairs(tile.border) do
                    local tex = select(1, borderFrame:GetRegions())
                    if isEquipped then
                        if tex then tex:SetColorTexture(ac.r, ac.g, ac.b, ac.a) end
                        borderFrame:SetFrameLevel(tile:GetFrameLevel() + 100)
                    else
                        if tex then tex:SetColorTexture(0, 0, 0, 1) end
                        borderFrame:SetFrameLevel(tile:GetFrameLevel() + 10)
                    end
                end
            end

            local hasSpec = false
            if setData.spec then
                local _, _, _, specIcon = GetSpecializationInfo(setData.spec)
                if specIcon then
                    tile._specIcon:SetTexture(specIcon)
                    tile._specIconFrame:Show()
                    hasSpec = true
                end
            end
            if not hasSpec then
                tile._specIconFrame:Hide()
            end

            tile._del:ClearAllPoints()
            if hasSpec then
                tile._del:SetPoint("RIGHT", tile._specIconFrame, "LEFT", 0, 0)
            else
                tile._del:SetPoint("RIGHT", tile, "RIGHT", -1, 0)
            end

            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", equipScrollChild, "TOPLEFT", 5, yOffset)
            tile:Show()
            yOffset = yOffset - TILE_STEP
        end

        for i = #equipmentSets + 1, #setTilePool do
            setTilePool[i]:Hide()
        end

        equipScrollChild:SetHeight(-yOffset)
    end

    local function RefreshEquipSetColors()
        if not (equipPanel:IsShown()) then
            return
        end

        local equippedIDs = {}
        local setIDs = C_EquipmentSet.GetEquipmentSetIDs()
        if setIDs then
            for _, setID in ipairs(setIDs) do
                local _, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)
                if isEquipped then
                    equippedIDs[setID] = true
                end
            end
        end

        for _, tile in ipairs(setTilePool) do
            if tile:IsShown() and tile._setText and tile._setName then
                if IsEquipmentSetComplete(tile._setName) then
                    tile._setText:SetTextColor(1, 1, 1, 1)
                else
                    tile._setText:SetTextColor(1, 0.3, 0.3, 1)
                end

                if tile._bg then
                    tile._bg:SetColorTexture(med.r, med.g, med.b, med.a)
                end

                if tile._selection then
                    if tile._setID and tile._setID == selectedSetID then
                        tile._selection:SetColorTexture(ac.r, ac.g, ac.b, 0.15)
                        tile._selection:Show()
                    else
                        tile._selection:Hide()
                    end
                end

                if tile.border and tile._setID then
                    local isEquipped = equippedIDs[tile._setID]
                    for _, borderFrame in pairs(tile.border) do
                        local tex = select(1, borderFrame:GetRegions())
                        if isEquipped then
                            if tex then tex:SetColorTexture(ac.r, ac.g, ac.b, ac.a) end
                            borderFrame:SetFrameLevel(tile:GetFrameLevel() + 100)
                        else
                            if tex then tex:SetColorTexture(0, 0, 0, 1) end
                            borderFrame:SetFrameLevel(tile:GetFrameLevel() + 10)
                        end
                    end
                end
            end
        end
    end

    local _refreshPending = false
    local _colorRefreshPending = false

    local function QueueFullRefresh()
        if _refreshPending then return end
        _refreshPending = true
        C_Timer.After(0.01, function()
            _refreshPending = false
            if equipPanel:IsShown() then
                RefreshEquipmentSets()
            end
        end)
    end

    local function QueueColorRefresh()
        if _colorRefreshPending then return end
        _colorRefreshPending = true
        -- timer needed for gear to appear in bags lol
        C_Timer.After(0.7, function()
            _colorRefreshPending = false
            RefreshEquipSetColors()
        end)
    end

    local equipmentColorMonitor = CreateFrame("Frame")
    equipmentColorMonitor:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    equipmentColorMonitor:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
    equipmentColorMonitor:RegisterEvent("EQUIPMENT_SETS_CHANGED")
    equipmentColorMonitor:SetScript("OnEvent", QueueColorRefresh)

    local equipSetChangeFrame = CreateFrame("Frame")
    equipSetChangeFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
    equipSetChangeFrame:SetScript("OnEvent", QueueFullRefresh)

    equipPanel:HookScript("OnShow", function()
        RefreshEquipmentSets()
    end)

    return equipPanel
end