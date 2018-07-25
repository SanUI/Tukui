--[[
	** Based on Butsu by Haste **
	** Build for Tukui by Aftermathh **
--]]

local T, C, L = select(2, ...):unpack()
local Inventory = T["Inventory"]
local CustomLoot = CreateFrame("Frame")

-- Lib Globals
local _G = _G
local select = select
local unpack = unpack
local pairs = pairs
local max = math.max
local tinsert = table.insert

-- WoW Globals
local LootSlotHasItem = LootSlotHasItem
local CursorUpdate = CursorUpdate
local CursorOnUpdate = CursorOnUpdate
local ResetCursor = ResetCursor
local IsModifiedClick = IsModifiedClick
local GetLootSlotLink = GetLootSlotLink
local StaticPopup_Hide = StaticPopup_Hide
local CloseLoot = CloseLoot
local IsFishingLoot = IsFishingLoot
local UnitIsDead = UnitIsDead
local UnitIsFriend = UnitIsFriend
local UnitName = UnitName
local GetCVarBool = GetCVarBool
local GetCursorPosition = GetCursorPosition
local GetNumLootItems = GetNumLootItems
local GetLootSlotInfo = GetLootSlotInfo

function CustomLoot:OnEnter()
--local OnEnter = function(self)
	self.drop:SetStatusBarColor(1, 1, 1, 0.10)
	self.drop:Show()

	local slot = self:GetID()
	if LootSlotHasItem(slot) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetLootItem(slot)
		CursorUpdate(self)
	end
end

function CustomLoot:OnLeave()
	self.drop:SetStatusBarColor(0, 0, 0, 0)
	self.drop:Hide()

	GameTooltip:Hide()
	ResetCursor()
end

function CustomLoot:OnClick()
	LootFrame.selectedQuality = self.quality
	LootFrame.selectedItemName = self.name:GetText()
	LootFrame.selectedSlot = self:GetID()
	LootFrame.selectedLootButton = self:GetName()
	LootFrame.selectedTexture = self.icon:GetTexture()

	if IsModifiedClick() then
		HandleModifiedItemClick(GetLootSlotLink(self:GetID()))
	else
		StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION")
		LootSlot(self:GetID())
	end
end

function CustomLoot:OnShow()
	if GameTooltip:IsOwned(self) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetLootItem(self:GetID())
		CursorOnUpdate(self)
	end
end

function CustomLoot:AnchorSlots()
	local shownSlots = 0
	for i = 1, #self.LootSlots do
		local frame = self.LootSlots[i]
		if frame:IsShown() then
			shownSlots = shownSlots + 1

			frame:Point("TOP", CustomLootFrame, 4, (-8 + CustomLoot.IconSize) - (shownSlots * (CustomLoot.IconSize+1)))
		end
	end

	self:Height(max(shownSlots * CustomLoot.IconSize + 16, 20))
end

function CustomLoot:CreateSlots(id)
	local IconSize = (CustomLoot.IconSize - 2)

	local frame = CreateFrame("Button", "TukuiLootSlot"..id, CustomLootFrame)
	frame:Height(IconSize)
	frame:Point("LEFT", 8, 0)
	frame:Point("RIGHT", -8, 0)
	frame:CreateBackdrop()
	frame:CreateShadow()
	frame:SetID(id)
	
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	frame:SetScript("OnEnter", CustomLoot.OnEnter)
	frame:SetScript("OnLeave", CustomLoot.OnLeave)
	frame:SetScript("OnClick", CustomLoot.OnClick)
	frame:SetScript("OnShow", CustomLoot.OnShow)

	local iconFrame = CreateFrame("Frame", nil, frame)
	iconFrame:Size(IconSize, IconSize)
	iconFrame:Point("RIGHT", frame, "LEFT", -2, 0)
	iconFrame:SetTemplate()
	iconFrame:CreateShadow()
	frame.iconFrame = iconFrame

	local icon = iconFrame:CreateTexture(nil, "ARTWORK")
	icon:SetTexCoord(.1, .9, .1, .9)
	icon:SetInside()
	frame.icon = icon
	
	local invsframe = CreateFrame("Frame", nil, frame)
	invsframe:SetFrameLevel(frame:GetFrameLevel() + 5)
	invsframe:SetAllPoints()
	frame.invsframe = invsframe

	local count = iconFrame:CreateFontString(nil, "OVERLAY")
	count:SetJustifyH("RIGHT")
	count:Point("BOTTOMRIGHT", iconFrame, -2, 4)
	count:SetFontTemplate(C.Medias.Font, 12)
	count:SetText(1)
	frame.count = count

	local name = invsframe:CreateFontString(nil, "OVERLAY")
	name:Point("RIGHT", invsframe)
	name:Point("LEFT", icon, "RIGHT", 4, 0)
	name:SetNonSpaceWrap(true)
	name:SetFontTemplate(C.Medias.Font, 12)
	frame.name = name
	
	local drop = CreateFrame("StatusBar", nil, frame)
	drop:SetFrameLevel(frame:GetFrameLevel() + 5)
	drop:SetInside(frame, 1, 1)
	drop:SetStatusBarTexture(C.Medias.Blank)
	drop:SetStatusBarColor(0, 0, 0, 0)
	frame.drop = drop
	
	CustomLootFrame.LootSlots[id] = frame
	
	return frame
end

function CustomLoot:LOOT_SLOT_CLEARED(_, slot)
	if not CustomLootFrame:IsShown() then 
		return 
	end

	CustomLootFrame.LootSlots[slot]:Hide()
	CustomLoot.AnchorSlots(CustomLootFrame)
end

function CustomLoot:LOOT_CLOSED()
	StaticPopup_Hide("LOOT_BIND")
	CustomLootFrame:Hide()

	for _, v in pairs(CustomLootFrame.LootSlots) do
		v:Hide()
	end
end

function CustomLoot:LOOT_OPENED(_, autoloot)
	CustomLootFrame:Show()

	if not CustomLootFrame:IsShown() then
		CloseLoot(not autoLoot)
	end
	
	if IsFishingLoot() then
		CustomLootFrame.Title:SetText("Fishy Loot")
	elseif not UnitIsFriend("player", "target") and UnitIsDead("target") then
		CustomLootFrame.Title:SetText(UnitName("target"))
	else
		CustomLootFrame.Title:SetText(LOOT)
	end

	if GetCVarBool("lootUnderMouse") then
		local x, y = GetCursorPosition()
		x = x / CustomLootFrame:GetEffectiveScale()
		y = y / CustomLootFrame:GetEffectiveScale()

		CustomLootFrame:ClearAllPoints()
		CustomLootFrame:Point("TOPLEFT", UIParent, "BOTTOMLEFT", x - 40, y + 20)
		CustomLootFrame:GetCenter()
		CustomLootFrame:Raise()
	else
		CustomLootFrame:ClearAllPoints()
		CustomLootFrame:Point("TOPLEFT", CustomLootFrame, "TOPLEFT", 0, 0)
	end

	local Items = GetNumLootItems()

	if (Items > 0) then
		for i = 1, Items do
			local Texture, Item, Quantity, _, Quality, _, IsQuestItem, QuestID, isActive = GetLootSlotInfo(i)

			if (GetLootSlotType(i) == LOOT_SLOT_MONEY) then
				Item = Item:gsub("\n", ", ")
			end
			
			local LootFrameSlots = CustomLootFrame.LootSlots[i] or CustomLoot:CreateSlots(i)
			local Color = ITEM_QUALITY_COLORS[Quality]
			
			if (Quantity and Quantity > 1) then
				LootFrameSlots.count:SetText(Quantity)
				LootFrameSlots.count:Show()
			else
				LootFrameSlots.count:Hide()
			end

			if (QuestID and not isActive) then
				LootFrameSlots.name:SetTextColor(1, 0.82, 0)
				LootFrameSlots:SetBackdropColor(Color.r * 0.55, Color.g * 0.55, Color.b * 0.55, 0.25)
			elseif (QuestID or IsQuestItem) then
				LootFrameSlots.name:SetTextColor(1, 0.82, 0)
				LootFrameSlots:SetBackdropColor(Color.r * 0.55, Color.g * 0.55, Color.b * 0.55, 0.25)
			else
				LootFrameSlots.name:SetTextColor(Color.r, Color.g, Color.b)
				LootFrameSlots:SetBackdropColor(Color.r * 0.55, Color.g * 0.55, Color.b * 0.55, 0.25)
			end

			LootFrameSlots.quality = Quality
			LootFrameSlots.name:SetText(Item)
			LootFrameSlots.icon:SetTexture(Texture)

			LootFrameSlots:Enable()
			LootFrameSlots:Show()
		end
	else
		local LootFrameSlots = CustomLootFrame.LootSlots[1] or CustomLoot:CreateSlots(1)
		local Color = ITEM_QUALITY_COLORS[0]

		LootFrameSlots.name:SetText("Empty Slot")
		LootFrameSlots.name:SetTextColor(Color.r, Color.g, Color.b)
		LootFrameSlots.icon:SetTexture([[Interface\Icons\INV_Misc_Herb_AncientLichen]])

		LootFrameSlots.count:Hide()
		LootFrameSlots.drop:Hide()
		LootFrameSlots:Disable()
		LootFrameSlots:Show()
	end

	CustomLoot.AnchorSlots(CustomLootFrame)
end

function CustomLoot:Enable()
	-- Locals
	self.IconSize = 32
	
	CustomLootFrame = CreateFrame("Button", "TukuiLootFrame", UIParent)
	CustomLootFrame:SetClampedToScreen(true)
	CustomLootFrame:SetToplevel(true)
	CustomLootFrame:Size(198, 58)
	CustomLootFrame.LootSlots = {}
	CustomLootFrame:SetScript("OnHide", function()
		StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION")
		CloseLoot()
	end)
	
	CustomLootFrame.Overlay = CreateFrame("Frame", nil, CustomLootFrame)
	CustomLootFrame.Overlay:Size(198+16, 28)
	CustomLootFrame.Overlay:Point("TOP", CustomLootFrame, -16, 22)
	CustomLootFrame.Overlay:CreateBackdrop()
	CustomLootFrame.Overlay:CreateShadow()
	
	CustomLootFrame.InvisFrame = CreateFrame("Frame", nil, CustomLootFrame)
	CustomLootFrame.InvisFrame:SetFrameLevel(CustomLootFrame:GetFrameLevel() + 5)
	CustomLootFrame.InvisFrame:SetAllPoints()
	
	CustomLootFrame.Title = CustomLootFrame.InvisFrame:CreateFontString(nil, "OVERLAY", 7)
	CustomLootFrame.Title:SetFontTemplate(C.Medias.Font, 14)
	CustomLootFrame.Title:Point("CENTER", CustomLootFrame.Overlay, 0, 1)
	CustomLootFrame.Title:SetTextColor(1, 0.82, 0)
	
	self:RegisterEvent("LOOT_OPENED")
	self:RegisterEvent("LOOT_SLOT_CLEARED")
	self:RegisterEvent("LOOT_CLOSED")
	
	self:SetScript("OnEvent", function(self, event, ...)
		self[event](self, event, ...)
	end)
	
	LootFrame:UnregisterAllEvents()
	tinsert(UISpecialFrames, "TukuiLootFrame")
end

Inventory.Loot = CustomLoot