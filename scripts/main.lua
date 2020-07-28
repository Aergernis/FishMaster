local name, _FishMaster = ...;

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
    text = "Gatherlite",
    icon = _FishMaster.iconPath .. "Fishhook",

    OnClick = function(self, button)
        if button == "LeftButton" then
            --FishMaster.equipment:Toggle()

            if FishMaster.db.char.enabled then
                for key, item in pairs(FishMaster.db.char.storedOutfit) do
                    EquipItemByName(item, key);
                    FishMaster.db.char.storedOutfit[key] = nil;
                    FishMaster.db.char.enabled = false;
                end
            else
                local pole = FishMaster:FindBestPole();
                if pole then
                    FishMaster.db.char.storedOutfit[INVSLOT_MAINHAND] = GetInventoryItemID("player", INVSLOT_MAINHAND);
                    EquipItemByName(FishMaster:FindBestPole(), INVSLOT_MAINHAND);
                    FishMaster.db.char.enabled = true;
                end
            end
        elseif button == "RightButton" then
            InterfaceOptionsFrame_OpenToCategory(name)
            InterfaceOptionsFrame_OpenToCategory(name) -- run it again to set the correct tab
        end
    end,

    OnTooltipShow = function(tooltip)
        tooltip:SetText(_FishMaster.name .. " |cFF00FF00" .. _FishMaster.version .. "|r");
        tooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.left_click"), 'gray') .. ": " .. FishMaster:translate("minimap.left_click_text"));
        tooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.right_click"), 'gray') .. ": " .. FishMaster:translate("minimap.right_click_text"));
    end,
});

function FishMaster:CreateMainButton()
    local texture = "Interface\\Icons\\inv_fishingpole_02";
    local pfb = CreateFrame("BUTTON", "Poisoner_FreeButton", UIParent, "SecureActionButtonTemplate");

    local size = 42
    pfb:RegisterForClicks("AnyUp")
    pfb:RegisterForDrag("LeftButton");
    pfb:SetMovable(true);
    pfb:SetSize(size, size)
    pfb:SetScale(1)
    pfb:SetAlpha(1)

    pfb:SetScript("OnEnter", function(self)
        GameTooltip:ClearLines();
        GameTooltip:SetOwner(self, "ANCHOR_MIDDLELEFT");

        GameTooltip:SetText(_FishMaster.name .. " |cFF00FF00" .. _FishMaster.version .. "|r");
        GameTooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.left_click"), 'gray') .. ": " .. FishMaster:translate("button.left_click_text"));
        GameTooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.right_click"), 'gray') .. ": " .. FishMaster:translate("button.right_click_text"));

        GameTooltip:Show();
    end);

    pfb:SetScript("OnLeave", function(self)
        GameTooltip:ClearLines();
        GameTooltip:Hide();
    end);

    pfb:ClearAllPoints();

    pfb:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    pfb:SetFrameStrata("MEDIUM")
    pfb:SetFrameLevel(1)

    if not pfb.Texture then
        pfb.Texture = pfb:CreateTexture(pfb:GetName() .. "Icon", "ARTWORK");
    end
    pfb.Texture:SetTexture(texture)
    pfb.Texture:ClearAllPoints()
    pfb.Texture:SetPoint("CENTER", pfb, "CENTER", 0, 0)
    pfb.Texture:SetTexCoord(0, 1, 0, 1)

    pfb.Texture:SetSize(size, size)
    pfb:SetNormalTexture(texture)
    pfb:SetHighlightTexture(texture)
    local tex = pfb:GetNormalTexture()
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", pfb, "CENTER", 0, 0)
    tex:SetSize(size, size)
    pfb:Show()

    pfb:SetAttribute("type", "macro");

    pfb:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self.IsMoving = true
    end);
    pfb:SetScript("OnDragStop", function(self)
        if self.IsMoving == true then
            self:StopMovingOrSizing()
            self.IsMoving = false
        end
    end);

    pfb:SetScript("OnUpdate", function(self)

        local text = "";

        local lured = FishMaster:IsLured();

        local lure = FishMaster:FindBestLure();

        if not lured and lure and FishMaster.db.char.autoLure then
            local name, rank, icon = GetSpellInfo(lure.spell)
            text = text .. "/use " .. name .. "\n";
            text = text .. "/use 16\n";
        else
            if lure then
                local name, rank, icon = GetSpellInfo(lure.spell)
                text = text .. "/use [button:2] " .. name .. "\n";
                text = text .. "/use [button:2] 16\n";
            end
            text = text .. "/use [button:1] Fishing\n";
        end

        --if not lured and FishMaster.db.char.autoLure then

        --else

        --end
        self:SetAttribute("macrotext", text)
    end);
    pfb:SetClampedToScreen(true);

    _FishMaster.mainButton = pfb;
end

function FishMaster:CreateLureButtons()
    for key, lure in pairs(_FishMaster.lures) do
        local button = CreateFrame("BUTTON", "FishMasterLure_" .. key, Poisoner_FreeButton, "BagBuddyItemTemplate");

        local size = 32
        button:RegisterForClicks("AnyUp")
        button:RegisterForDrag("LeftButton");
        button:SetMovable(true);
        button:SetSize(size, size)
        button:SetScale(1)
        button:SetAlpha(1)

        if key == 1 then
            button:SetPoint("TOPLEFT", Poisoner_FreeButton, "TOPRIGHT", 5, 0)
        else
            button:SetPoint("TOPLEFT", _G["FishMasterLure_" .. key - 1], "TOPRIGHT", 2, 0)
        end

        button:SetFrameStrata("MEDIUM")
        button:SetFrameLevel(1)

        button:SetAttribute("lure", lure);

        button:SetScript("OnEnter", function(self)
            GameTooltip:ClearLines();
            GameTooltip:SetOwner(self, "ANCHOR_LEFT");

            local name, link = GetItemInfo(self:GetAttribute("item"))

            GameTooltip:SetHyperlink(link);
            GameTooltip:Show();
        end);

        button:SetScript("OnLeave", function(self)
            GameTooltip:ClearLines();
            GameTooltip:Hide();
        end);

        button:SetScript("OnUpdate", function(self)
            local lure = self:GetAttribute("lure");
            local count = GetItemCount(lure.item);

            _G[self:GetName() .. "Count"]:SetText(count);

            if count == 0 then
                self:SetAlpha(.2);
                self:EnableMouse(false);
            elseif FishMaster:GetProfessionLevel("fishing") < lure.skill then
                self:SetAlpha(.2);
                self:EnableMouse(false);
            else
                self:SetAlpha(1);
                self:EnableMouse(true);
            end
        end);

        _G["FishMasterLure_" .. key .. "IconTexture"]:SetTexture(lure.icon)
        _G["FishMasterLure_" .. key .. "Count"]:SetText(2)
        _G["FishMasterLure_" .. key .. "Count"]:Show()

        local spellName, rank, icon = GetSpellInfo(lure.spell)
        local text = "";
        text = text .. "/use " .. spellName .. "\n";
        text = text .. "/use 16\n";
        button:SetAttribute("name", spellName)
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", text)
        button:SetAttribute("item", lure.item)
        button:SetClampedToScreen(true);
    end
end

function FishMaster:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("FishMasterSettings", _FishMaster.configsDefaults, true)
    self.minimap = LibStub("LibDBIcon-1.0")
    FishMaster.minimap:Register("FishMasterMinimapIcon", minimapIcon, self.db.profile.minimap)
    FishMaster:ScheduleRepeatingTimer("CheckEnabled", 1)
    FishMaster.equipment:OnLoad()

    FishMaster:RegisterEvent("UNIT_INVENTORY_CHANGED", "EventHandler")
    FishMaster:RegisterEvent("BAG_UPDATE", "EventHandler")
    FishMaster:RegisterEvent("LOOT_OPENED", "EventHandler")
    FishMaster:RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler")

    FishMaster:CreateMainButton()
    FishMaster:CreateLureButtons()
end
