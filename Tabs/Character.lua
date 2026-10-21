local SCS = SwirlCharacterStats
local issecretvalue = issecretvalue or function() return false end

local function HexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        r = tonumber(hex:sub(1, 2), 16) / 255,
        g = tonumber(hex:sub(3, 4), 16) / 255,
        b = tonumber(hex:sub(5, 6), 16) / 255,
    }
end

local statSectionColors = {
    core = HexToRGB("#7ee5ff"),
    secondary = HexToRGB("#89ff7f"),
    tertiary = HexToRGB("#ffd700"),
    attack = HexToRGB("#ff69b4"),
    defence = HexToRGB("#d0a3ff"),
    -- crests = HexToRGB("#ffc857"),
    pvp = HexToRGB("#BE3131"),
}

local percentAbbrevData = {
    breakpointData = {
        {
            breakpoint = 0,
            abbreviation = "%",
            significandDivisor = 0.01,
            fractionDivisor = 100,
            abbreviationIsGlobal = false,
        },
    }
}

local crestCurrencyData = {
    {id = 3347, name = "Myth Crests", tooltip = "Mythic difficulty upgrade currency."},
    {id = 3345, name = "Hero Crests", tooltip = "Heroic difficulty upgrade currency."},
    {id = 3343, name = "Champion Crests", tooltip = "Champion difficulty upgrade currency."},
    {id = 3341, name = "Veteran Crests", tooltip = "Veteran difficulty upgrade currency."},
    {id = 3383, name = "Adventurer Crests", tooltip = "Adventurer difficulty upgrade currency."},
}

local function GetCrestQuantity(ccyId)
    local ccyInfo = C_CurrencyInfo.GetCurrencyInfo(ccyId)
    if ccyInfo then
        return ccyInfo.quantity or 0
    end
    return 0
end

local function GetCrestEarnedRatioStr(ccyId)
    local ccyInfo = C_CurrencyInfo.GetCurrencyInfo(ccyId)
    if ccyInfo then
        return string.format("(%s/%s)", ccyInfo.totalEarned, ccyInfo.maxQuantity)
    end
    return "0/0"
end

local function GetBlizzardStatValue(statName)
    if not CharacterStatsPane then return nil end

    local function FindStatFrame(parent, name)
        if not parent then return nil end

        local children = {parent:GetChildren()}
        for _, child in ipairs(children) do
            if child.Label then
                local labelText = child.Label:GetText()
                if labelText and string.find(labelText, name, 1, true) then
                    return child
                end
            end

            local found = FindStatFrame(child, name)
            if found then return found end
        end

        return nil
    end

    local statFrame = FindStatFrame(CharacterStatsPane, statName)
    if statFrame and statFrame.Value then
        return statFrame.Value:GetText()
    end

    return nil
end

local function GetMplusScore()
    local score = C_ChallengeMode.GetOverallDungeonScore() or 0
    local scoreColor = C_ChallengeMode.GetDungeonScoreRarityColor(score)
    local scoreStr = string.format(
        "M+ Rating: %s", scoreColor:WrapTextInColorCode(tostring(score))
    )
    return scoreStr
end

local function GetPrimaryStatData()
    local statNames = {
        [1] = { name = "Strength", tooltip = "Increases physical damage and healing." },
        [2] = { name = "Agility", tooltip = "Increases physical damage, critical strike chance, and dodge chance." },
        [4] = { name = "Intellect", tooltip = "Increases spell power and mana pool." },
    }

    local specIndex = GetSpecialization()
    local primaryStat = 1

    if specIndex then
        local _, _, _, _, _, statIndex = C_SpecializationInfo.GetSpecializationInfo(specIndex)
        primaryStat = statIndex or 1
    end

    local statInfo = statNames[primaryStat]

    return {
        name = statInfo.name,
        func = function() return UnitStat("player", primaryStat) end,
        useComma = true,
        tooltip = statInfo.tooltip,
    }
end

local function GetStatSectionsOrder()
    return {
        {
            title = "Core",
            color = statSectionColors.core,
            stats = function()
                return {
                    GetPrimaryStatData(),
                    {
                        name = "Stamina",
                        func = function() return UnitStat("player", 3) end,
                        useComma = true,
                        tooltip = "Increases health.",
                    },
                    {
                        name = "Health",
                        func = function() return UnitHealthMax("player") end,
                        format = "%s",
                        useComma = true,
                        tooltip = "Maximum health.",
                    },
                }
            end,
        },
        {
            title = "Secondary",
            color = statSectionColors.secondary,
            stats = function()
                return {
                    {
                        name = "Haste",
                        func = function()
                            return GetHaste()
                        end,
                        rawFunc = function() return GetCombatRating(CR_HASTE_MELEE) end,
                        format = "%.2f%%",
                        tooltip = "Increases attack and cast speed.",
                    },
                    {
                        name = "Critical Strike",
                        func = function()
                            return GetCritChance()
                        end,
                        rawFunc = function() return GetCombatRating(CR_CRIT_MELEE) end,
                        format = "%.2f%%",
                        tooltip = "Increases your chance to critically hit.",
                    },
                    {
                        name = "Versatility",
                        func = function()
                            local bonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0
                            local vers = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE) or 0
                            if issecretvalue(bonus) or issecretvalue(vers) then
                                return GetBlizzardStatValue("Versatility")
                            end
                            return bonus + vers
                        end,
                        rawFunc = function() return GetCombatRating(CR_VERSATILITY_DAMAGE_DONE) end,
                        format = "%.2f%%",
                        tooltip = "Increases damage and healing done, and reduces damage taken.",
                    },
                    {
                        name = "Mastery",
                        func = function()
                            return GetMasteryEffect()
                        end,
                        rawFunc = function() return GetCombatRating(CR_MASTERY) end,
                        format = "%.2f%%",
                        tooltip = "Increases your effectiveness in your chosen specialization.",
                    },
                }
            end,
        },
        {
            title = "Tertiary",
            color = statSectionColors.tertiary,
            stats = function()
                return {
                    {
                        name = "Leech",
                        func = function()
                            return GetLifesteal()
                        end,
                        rawFunc = function() return GetCombatRating(CR_LIFESTEAL) end,
                        format = "%.2f%%",
                        tooltip = "Heals you for a percentage of damage and healing done.",
                    },
                    {
                        name = "Avoidance",
                        func = function()
                            return GetAvoidance()
                        end,
                        rawFunc = function() return GetCombatRating(CR_AVOIDANCE) end,
                        format = "%.2f%%",
                        tooltip = "Reduces damage taken from area attacks.",
                    },
                    {
                        name = "Speed",
                        func = function()
                            return GetCombatRatingBonus(CR_SPEED)
                        end,
                        rawFunc = function() return GetCombatRating(CR_SPEED) end,
                        format = "%.2f%%",
                        tooltip = "Increases movement speed.",
                    },
                }
            end,
        },
        {
            title = "Attack",
            color = statSectionColors.attack,
            stats = function()
                return {
                    {
                        name = "Attack Power",
                        func = function()
                            local base, pos, neg = UnitAttackPower("player")
                            if issecretvalue(base) or issecretvalue(pos) or issecretvalue(neg) then
                                return base
                            end
                            return base + pos + neg
                        end,
                        format = "%s",
                        useComma = true,
                        tooltip = "Increases physical damage.",
                    },
                    {
                        name = "Spell Power",
                        func = function() return GetSpellBonusDamage(2) end,
                        format = "%s",
                        useComma = true,
                        tooltip = "Increases spell damage and healing.",
                    },
                }
            end,
        },
        {
            title = "Defence",
            color = statSectionColors.defence,
            stats = function()
                return {
                    {
                        name = "Armor",
                        func = function()
                            local base, effectiveArmor = UnitArmor("player")
                            return effectiveArmor
                        end,
                        format = "%s",
                        useComma = true,
                        tooltip = "Reduces physical damage taken.",
                    },
                    {
                        name = "Dodge",
                        func = function()
                            return GetDodgeChance()
                        end,
                        format = "%.2f%%",
                        tooltip = "Chance to completely avoid an attack.",
                    },
                    {
                        name = "Parry",
                        func = function()
                            return GetParryChance()
                        end,
                        format = "%.2f%%",
                        tooltip = "Chance to parry an attack.",
                    },
                    {
                        name = "Block",
                        func = function()
                            return GetBlockChance()
                        end,
                        format = "%.2f%%",
                        tooltip = "Chance to block an attack with your shield.",
                    },
                    {
                        name = "Stagger",
                        func = function()
                            local stagger = UnitStagger("player") or 0
                            local maxHealth = UnitHealthMax("player") or 1
                            if issecretvalue(stagger) or issecretvalue(maxHealth) then
                                return GetBlizzardStatValue("Stagger")
                            end
                            return (stagger / maxHealth) * 100
                        end,
                        format = "%.1f%%",
                        tooltip = "Percentage of recent damage being staggered.",
                    },
                }
            end,
        },
        -- {
        --     title = "Crests",
        --     color = statSectionColors.crests,
        --     stats = function()
        --         local stats = {}
        --         for _, crest in ipairs(crestCurrencyData) do
        --             table.insert(stats, {
        --                 name = crest.name,
        --                 func = function() return GetCrestQuantity(crest.id) end,
        --                 max = function() return GetCrestEarnedRatioStr(crest.id) end,
        --                 format = "%d",
        --                 tooltip = crest.tooltip,
        --             })
        --         end
        --         return stats
        --     end,
        -- },
        {
            title = "PvP",
            color = statSectionColors.pvp,
            stats = function()
                local currentHonorLevel = UnitHonorLevel("player") or 0
                local currentHonor, maxHonor = UnitHonor("player"), UnitHonorMax("player")
                local honorText = string.format("%d / %d", currentHonor or 0, maxHonor or 1)

                return {
                    {
                        name = "Honor Level",
                        func = function() return currentHonorLevel end,
                        format = "%d",
                        tooltip = "Your current honor level.",
                    },
                    {
                        name = "Honor",
                        func = function() return honorText end,
                        format = "%s",
                        tooltip = "Honor points toward next level.",
                    },
                }
            end,
        },
    }
end

function FormatNumber(num)
    if not num then return "0" end
    if issecretvalue(num) then return tostring(num) end
    local formatted = tostring(math.floor(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

function SCS.CreateStatsPanel(parent)
    local statsPanel = CreateFrame("Frame", "SCS_StatsPanel", parent, "BackdropTemplate")
    statsPanel:SetWidth(SCS.panelWidth)

    local t = SwirlUI and SwirlUI.Theme
    local C = SwirlUI and SwirlUI.Components
    C.SetBackdrop(statsPanel, CreateColor(t.bg.dark.r, t.bg.dark.g, t.bg.dark.b, 0.90), t.border.color)

    local HEADER_H = 75
    local scrollFrame = CreateFrame("ScrollFrame", "SCS_StatsScrollFrame", statsPanel)
    scrollFrame:SetPoint("TOPLEFT", statsPanel, "TOPLEFT", 1, -HEADER_H - 1)
    scrollFrame:SetPoint("BOTTOMRIGHT", statsPanel, "BOTTOMRIGHT", -1, 1)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetClipsChildren(true)

    local scrollTopBorder = scrollFrame:CreateTexture(nil, "OVERLAY")
    scrollTopBorder:SetColorTexture(0, 0, 0, 1)
    scrollTopBorder:SetHeight(1)
    scrollTopBorder:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    scrollTopBorder:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)

    local scrollChild = CreateFrame("Frame", "SCS_StatsScrollChild", scrollFrame)
    scrollChild:SetWidth(184)
    scrollFrame:SetScrollChild(scrollChild)

    SCS.AttachCustomScrollbar(scrollFrame, scrollChild, {
        trackOwner = statsPanel,
        topInset = -HEADER_H - 1,
        bottomInset = 1,
    })

    local ilvlText = statsPanel:CreateFontString(nil, "OVERLAY")
    ilvlText:SetFont(t.font.path, 18, "OUTLINE")
    ilvlText:SetShadowColor(0, 0, 0, 0)
    ilvlText:SetPoint("TOP", statsPanel, "TOP", 0, -33)
    ilvlText:SetTextColor(0.6, 0.2, 1, 1)
    local _, avgItemLevelEquipped = GetAverageItemLevel()
    ilvlText:SetText(tostring(math.floor(avgItemLevelEquipped or 0)))

    local ilvlButton = CreateFrame("Button", nil, statsPanel)
    ilvlButton:SetAllPoints(ilvlText)

    ilvlButton:SetScript("OnEnter", function()
        if CharacterStatsPane and CharacterStatsPane.ItemLevelFrame then
            local onEnterScript = CharacterStatsPane.ItemLevelFrame:GetScript("OnEnter")
            if onEnterScript then
                onEnterScript(CharacterStatsPane.ItemLevelFrame)
            end
            local _, equipped = GetAverageItemLevel()
            ilvlText:SetText(string.format("%.2f", equipped or 0))
        end
    end)

    ilvlButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
        local _, equipped = GetAverageItemLevel()
        ilvlText:SetText(tostring(math.floor(equipped or 0)))
    end)

    local mpScoreText = statsPanel:CreateFontString(nil, "OVERLAY")
    mpScoreText:SetFont(t.font.path, 10, "OUTLINE")
    mpScoreText:SetShadowColor(0, 0, 0, 0)
    mpScoreText:SetPoint("TOP", ilvlText, "BOTTOM", 0, -4)
    mpScoreText:SetText(GetMplusScore())

    statsPanel._statsValues = {}
    statsPanel._statsSections = {}

    local yOffset = -5
    local sections = GetStatSectionsOrder()

    for _, section in ipairs(sections) do
        local sectionContainer = CreateFrame("Frame", nil, scrollChild)
            sectionContainer:SetWidth(184)
            sectionContainer:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)

        local sectionData = {
            sectionTitle = section.title,
            container = sectionContainer,
            stats = {},
            isCollapsed = false,
            color = section.color,
        }
            table.insert(statsPanel._statsSections, sectionData)

            local titleContainer = CreateFrame("Button", nil, sectionContainer)
            titleContainer:SetHeight(14)
            titleContainer:SetPoint("TOPLEFT", sectionContainer, "TOPLEFT", 0, 0)
            titleContainer:SetPoint("TOPRIGHT", sectionContainer, "TOPRIGHT", 0, 0)

            local sectionTitle = titleContainer:CreateFontString(nil, "OVERLAY")
            sectionTitle:SetFont(t.font.path, 11, "OUTLINE")
            sectionTitle:SetShadowColor(0, 0, 0, 0)
            sectionTitle:SetText(section.title)
            sectionTitle:SetTextColor(section.color.r, section.color.g, section.color.b, 1)
            sectionTitle:SetPoint("CENTER", titleContainer, "CENTER", 0, 0)

            local leftLine = titleContainer:CreateTexture(nil, "OVERLAY", nil, 1)
            leftLine:SetColorTexture(section.color.r, section.color.g, section.color.b, 0.8)
            leftLine:SetHeight(1)
            leftLine:SetPoint("LEFT", titleContainer, "LEFT", 0, 0)
            leftLine:SetPoint("RIGHT", sectionTitle, "LEFT", -6, 0)

            local rightLine = titleContainer:CreateTexture(nil, "OVERLAY", nil, 1)
            rightLine:SetColorTexture(section.color.r, section.color.g, section.color.b, 0.8)
            rightLine:SetHeight(1)
            rightLine:SetPoint("LEFT", sectionTitle, "RIGHT", 6, 0)
            rightLine:SetPoint("RIGHT", titleContainer, "RIGHT", 0, 0)

            local statYOffset = -18
            local statsToShow = section.stats()

        for _, stat in ipairs(statsToShow) do
            local label = sectionContainer:CreateFontString(nil, "OVERLAY")
                    label:SetFont(t.font.path, 10, "OUTLINE")
                    label:SetShadowColor(0, 0, 0, 0)
                    label:SetText(stat.name)
                    label:SetTextColor(1, 1, 1, 1)
                    label:SetPoint("TOPLEFT", sectionContainer, "TOPLEFT", 0, statYOffset)

                    local value = sectionContainer:CreateFontString(nil, "OVERLAY")
                    value:SetFont(t.font.path, 10, "OUTLINE")
                    value:SetShadowColor(0, 0, 0, 0)
                    value:SetTextColor(1, 1, 1, 1)
                    value:SetPoint("TOPRIGHT", sectionContainer, "TOPRIGHT", 0, statYOffset)

                    local result = stat.func and stat.func()
                    if result ~= nil then
                        local fmt = stat.format or "%d"
                        if type(result) == "string" then
                            value:SetText(result)
                        elseif stat.max then
                            local maxVal = stat.max()
                            value:SetText(string.format("%d / %s", result, maxVal))
                        elseif stat.useComma then
                            value:SetText(FormatNumber(result))
                        elseif fmt:find("f%%%%") then
                            value:SetText(AbbreviateNumbers(result, percentAbbrevData))
                        else
                            value:SetText(string.format(fmt, result))
                        end
                    else
                        value:SetText("0")
                    end

                    local valueButton = CreateFrame("Button", nil, sectionContainer)
                    valueButton:SetAllPoints(label)
                    valueButton:SetPoint("RIGHT", value, "RIGHT", 0, 0)

                    valueButton:SetScript("OnEnter", function()
                        local handled = false

                        if CharacterStatsPane then
                            local function FindStatFrame(parent, statName)
                                if not parent then return nil end

                                local children = {parent:GetChildren()}
                                for _, child in ipairs(children) do
                                    if child.Label then
                                        local labelText = child.Label:GetText()
                                        if labelText and string.find(labelText, statName, 1, true) then
                                            return child
                                        end
                                    end
                                    local found = FindStatFrame(child, statName)
                                    if found then return found end
                                end

                                return nil
                            end

                            local blizzStatFrame = FindStatFrame(CharacterStatsPane, stat.name)
                            if blizzStatFrame then
                                local onEnterScript = blizzStatFrame:GetScript("OnEnter")
                                if onEnterScript then
                                    onEnterScript(blizzStatFrame)
                                    handled = true
                                end
                            end
                        end

                        if not handled then
                            GameTooltip:SetOwner(valueButton, "ANCHOR_CURSOR_RIGHT", 10, 0)
                            if stat.tooltip then
                                GameTooltip:SetText(stat.name, 1, 1, 1)
                                GameTooltip:AddLine(stat.tooltip, nil, nil, nil, true)

                                if stat.rawFunc then
                                    local rawValue = stat.rawFunc()
                                    if rawValue and rawValue > 0 then
                                        GameTooltip:AddLine(" ", 1, 1, 1)
                                        GameTooltip:AddLine(string.format("Rating: %d", rawValue), 0.8, 0.8, 0.8)
                                    end
                                end
                            end

                            GameTooltip:Show()
                        end
                    end)

                    valueButton:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)

                    table.insert(statsPanel._statsValues, {
                        value = value,
                        func = stat.func,
                        rawFunc = stat.rawFunc,
                        format = stat.format or "%d",
                        max = stat.max,
                        useComma = stat.useComma,
                    })

                    table.insert(sectionData.stats, {
                        label = label,
                        value = value,
                        button = valueButton,
                    })

                    local divider = sectionContainer:CreateTexture(nil, "OVERLAY")
                    divider:SetColorTexture(0.1, 0.1, 0.1, 0.5)
                    divider:SetHeight(1)
                    divider:SetPoint("LEFT", label, "RIGHT", 10, 0)
                    divider:SetPoint("RIGHT", value, "LEFT", -10, 0)
                    table.insert(sectionData.stats, {divider = divider})

            statYOffset = statYOffset - 16
        end

        sectionData.height = -statYOffset
        sectionContainer:SetHeight(sectionData.height)
        yOffset = yOffset - sectionData.height - 4
    end

    scrollChild:SetHeight(-yOffset)

    function statsPanel:UpdateAllStats()
        for _, statEntry in ipairs(self._statsValues) do
            local result = statEntry.func and statEntry.func()

            -- i hate secret values lmao
            if result == nil then
                statEntry.value:SetText("0")
            elseif type(result) == "string" then
                statEntry.value:SetText(result)
            elseif statEntry.max then
                local maxVal = statEntry.max()
                if issecretvalue(result) or issecretvalue(maxVal) then
                    statEntry.value:SetText(result)
                else
                    statEntry.value:SetText(string.format("%d / %s", result, maxVal))
                end
            elseif statEntry.useComma then
                if issecretvalue(result) then
                    statEntry.value:SetText(result)
                else
                    statEntry.value:SetText(FormatNumber(result))
                end
            elseif statEntry.format:find("f%%%%") then
                statEntry.value:SetText(AbbreviateNumbers(result, percentAbbrevData))
            else
                if issecretvalue(result) then
                    statEntry.value:SetText(result)
                else
                    statEntry.value:SetText(string.format(statEntry.format, result))
                end
            end
        end

        local _, avgItemLevelEquipped = GetAverageItemLevel()
        ilvlText:SetText(tostring(math.floor(avgItemLevelEquipped or 0)))

        mpScoreText:SetText(GetMplusScore())
    end

    function statsPanel:_recalculateSections()
        local yOffset = 0
        for _, sec in ipairs(self._statsSections) do
            sec.container:ClearAllPoints()
            sec.container:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
            local height = sec.isCollapsed and 14 or sec.height
            sec.container:SetHeight(height)
            yOffset = yOffset - height - 6
        end
        scrollChild:SetHeight(-yOffset)
    end

    statsPanel:UpdateAllStats()

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("UNIT_STATS")
    eventFrame:RegisterEvent("COMBAT_RATING_UPDATE")
    eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("HONOR_XP_UPDATE")
    eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    eventFrame:SetScript("OnEvent", function()
        if statsPanel:IsShown() then
            statsPanel:UpdateAllStats()
        end
    end)

    return statsPanel
end