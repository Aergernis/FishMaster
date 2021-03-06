local name, _FishMaster = ...;

--_FishMaster.callbacks = LibStub("CallbackHandler-1.0"):New(_FishMaster)
local SavedWFOnMouseDown;

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local minimapIcon = LibStub("LibDataBroker-1.1"):NewDataObject("FishMasterMinimapIcon", {
    type = "data source",
    text = _FishMaster.name,
    icon = _FishMaster.iconPath .. "Fishhook",

    OnClick = function(self, button)
        if button == "LeftButton" then
            FishMaster:Toggle();
        elseif button == "RightButton" then
            FishMaster.equipment:Toggle()
            --InterfaceOptionsFrame_OpenToCategory(name)
            --InterfaceOptionsFrame_OpenToCategory(name) -- run it again to set the correct tab
        end
    end,

    OnTooltipShow = function(tooltip)
        tooltip:SetText(_FishMaster.name .. " |cFF00FF00" .. _FishMaster.version .. "|r");
        tooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.left_click"), 'gray') .. ": " .. FishMaster:translate("minimap.left_click_text"));
        tooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.right_click"), 'gray') .. ": " .. FishMaster:translate("minimap.right_click_text"));
    end,
});

function FishMaster:Toggle()
    if _FishMaster.isCasting then
        return ;
    end

    FishMaster.db.char.enabled = not FishMaster.db.char.enabled;
    FishMaster:CheckEnabled();
    FishMaster:ToggleGear();
end

function FishMaster:ToggleGear()

    if FishMaster.db.char.enabled then

        if not FishMaster:HasPole() then
            return
        end

        if FishMaster.db.char.autoEquip then
            FishMaster.db.char.outfit["MainHandSlot"] = FishMaster:FindBestPole()
        end

        for key, slot in pairs(FishMaster:SlotInfo()) do
            FishMaster.db.char.storedOutfit[slot.name] = GetInventoryItemID("player", slot.id);
        end

        for slot, item in pairs(FishMaster.db.char.outfit) do
            local s = FishMaster:FindSlotInfo(slot);
            if s and FishMaster:FindItemInBags(item) then
                EquipItemByName(item, s.id);
            end
        end
        FishMaster:SetAudio(true)
    else
        for key, slot in pairs(FishMaster:SlotInfo()) do
            if GetInventoryItemID("player", slot.id) ~= FishMaster.db.char.storedOutfit[slot.name] then
                EquipItemByName(FishMaster.db.char.storedOutfit[slot.name], slot.id);
            end
        end
        FishMaster:UnsetAudio()
    end
end

function FishMaster:OnFishingBobber()
    if (GameTooltip:IsVisible() and GameTooltip:GetAlpha() == 1) then
        local text = GameTooltipTextLeft1:GetText() or self:GetLastTooltipText();
        return (text and string.find(text, FishMaster:translate("fishing.bobber")));
    end
end

function FishMaster:CheckForDoubleClick(button)
    if (button and button ~= "RightButton") then
        return false;
    end
    if (not LootFrame:IsShown() and self.lastClickTime) then
        local pressTime = GetTime();
        local doubleTime = pressTime - self.lastClickTime;
        if ((doubleTime < 0.4) and (doubleTime > 0.05)) then
            self.lastClickTime = nil;
            return true;
        end
    end
    self.lastClickTime = GetTime();
    if (self:OnFishingBobber()) then
        GameTooltip:Hide();
    end
    return false;
end

function FishMaster:GatherSlash(input)
    input = string.trim(input, " ");
    if input == "" or not input then
        FishMaster:Toggle()
        return ;
    elseif input == "config" then
        FishMaster.equipment:Toggle()
    end
end

function FishMaster:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("FishMasterSettings", _FishMaster.configsDefaults, true)
    self.minimap = LibStub("LibDBIcon-1.0")
    FishMaster.minimap:Register("FishMasterMinimapIcon", minimapIcon, self.db.profile.minimap)

    FishMaster:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "EventHandler")
    FishMaster:RegisterEvent("BAG_UPDATE", "EventHandler")
    FishMaster:RegisterEvent("LOOT_OPENED", "EventHandler")
    FishMaster:RegisterEvent("SKILL_LINES_CHANGED", "EventHandler")
    FishMaster:RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler")
    FishMaster:RegisterEvent("PLAYER_LEAVING_WORLD", "EventHandler")
    FishMaster:RegisterEvent("LOOT_OPENED", "EventHandler")
    FishMaster:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "EventHandler")
    FishMaster:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "EventHandler")
    FishMaster:RegisterEvent("UNIT_SPELLCAST_START", "EventHandler")
    FishMaster:RegisterEvent("UNIT_SPELLCAST_STOP", "EventHandler")

    FishMaster:On("OnItemSlotChange", "ItemSlotChange")

    FishMaster:On("Settings", function()
        FishMaster:CheckEnabled();
        local parent = _G['FishMaster_Toolbar'];
        FishMaster:ToolbarCast(parent.cast)

        FishMaster.tracker.Update()
        FishMaster.tracker.SetInfo();

    end)

    FishMaster:RegisterChatCommand("fmaster", "GatherSlash")
    FishMaster:RegisterChatCommand("fishmaster", "GatherSlash")

    if FishMaster.db.char.firstRun then
        local pole = FishMaster:FindBestPole();
        if pole then
            FishMaster.db.char.outfit["MainHandSlot"] = pole;
        end
        FishMaster.db.char.firstRun = false;
    end

    --FishMaster:CreateMainButton()
    --FishMaster:CreateLureButtons()
    FishMaster.equipment:OnLoad()
    FishMaster:CheckEnabled();
    FishMaster:SetAudio();
end