local HttpService = game:GetService("HttpService")

local InventoryConfig = require(script.Parent.InventoryConfig)
local InventoryDataStore = require(script.Parent.InventoryDataStore)
local ItemDefinitions = require(script.Parent.ItemDefinitions)

local InventoryService = {}
InventoryService.PlayerInventories = {}
InventoryService.InventoryChanged = Instance.new("BindableEvent")

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, nestedValue in pairs(value) do
		copy[key] = deepCopy(nestedValue)
	end
	return copy
end

local function createSlot(itemId, quantity, metadata)
	return {
		SlotId = HttpService:GenerateGUID(false),
		ItemId = itemId,
		Quantity = quantity,
		Metadata = metadata or {},
	}
end

local function getFilledSlotCount(inventory)
	local count = 0
	for _, slot in ipairs(inventory.Slots) do
		if slot.ItemId and slot.Quantity > 0 then
			count += 1
		end
	end
	return count
end

function InventoryService:CreateEmptyInventory()
	return {
		Slots = {},
		MaxSlots = InventoryConfig.MaxSlots,
		UpdatedAt = os.time(),
	}
end

function InventoryService:CreateDefaultInventory()
	local inventory = self:CreateEmptyInventory()

	for _, item in ipairs(InventoryConfig.DefaultInventory) do
		self:AddItemToInventory(inventory, item.ItemId, item.Quantity, item.Metadata)
	end

	return inventory
end

function InventoryService:SanitizeInventory(inventory)
	if type(inventory) ~= "table" then
		return self:CreateDefaultInventory()
	end

	inventory.Slots = type(inventory.Slots) == "table" and inventory.Slots or {}
	inventory.MaxSlots = tonumber(inventory.MaxSlots) or InventoryConfig.MaxSlots
	inventory.UpdatedAt = tonumber(inventory.UpdatedAt) or os.time()

	local sanitizedSlots = {}
	for _, slot in ipairs(inventory.Slots) do
		local itemId = slot.ItemId
		local quantity = math.floor(tonumber(slot.Quantity) or 0)
		local maxStack = ItemDefinitions:GetMaxStack(itemId)

		if maxStack and quantity > 0 then
			while quantity > 0 and #sanitizedSlots < inventory.MaxSlots do
				local stackQuantity = math.min(quantity, maxStack)
				table.insert(sanitizedSlots, createSlot(itemId, stackQuantity, slot.Metadata))
				quantity -= stackQuantity
			end
		end
	end

	inventory.Slots = sanitizedSlots
	return inventory
end

function InventoryService:LoadPlayer(player)
	local storedInventory = InventoryDataStore:Load(player)
	local inventory = self:SanitizeInventory(storedInventory)

	self.PlayerInventories[player.UserId] = inventory
	self.InventoryChanged:Fire(player, self:GetInventory(player))
	return inventory
end

function InventoryService:SavePlayer(player)
	local inventory = self.PlayerInventories[player.UserId]
	if not inventory then
		return false
	end

	inventory.UpdatedAt = os.time()
	return InventoryDataStore:Save(player, inventory)
end

function InventoryService:ReleasePlayer(player)
	self:SavePlayer(player)
	self.PlayerInventories[player.UserId] = nil
end

function InventoryService:GetInventory(player)
	local inventory = self.PlayerInventories[player.UserId]
	if not inventory then
		return nil
	end

	return deepCopy(inventory)
end

function InventoryService:GetLiveInventory(player)
	return self.PlayerInventories[player.UserId]
end

function InventoryService:AddItemToInventory(inventory, itemId, quantity, metadata)
	local requested = math.floor(tonumber(quantity) or 0)
	local remaining = requested
	local maxStack = ItemDefinitions:GetMaxStack(itemId)

	if not maxStack then
		return false, remaining, "Unknown item id"
	end

	if remaining <= 0 then
		return false, remaining, "Quantity must be positive"
	end

	for _, slot in ipairs(inventory.Slots) do
		if remaining <= 0 then
			break
		end

		local metadataMatches = HttpService:JSONEncode(slot.Metadata or {}) == HttpService:JSONEncode(metadata or {})
		if slot.ItemId == itemId and slot.Quantity < maxStack and metadataMatches then
			local amountToAdd = math.min(maxStack - slot.Quantity, remaining)
			slot.Quantity += amountToAdd
			remaining -= amountToAdd
		end
	end

	while remaining > 0 and getFilledSlotCount(inventory) < inventory.MaxSlots do
		local stackQuantity = math.min(maxStack, remaining)
		table.insert(inventory.Slots, createSlot(itemId, stackQuantity, metadata))
		remaining -= stackQuantity
	end

	inventory.UpdatedAt = os.time()
	return remaining < requested, remaining, remaining == 0 and nil or "Inventory is full"
end

function InventoryService:AddItem(player, itemId, quantity, metadata)
	local inventory = self:GetLiveInventory(player)
	if not inventory then
		return false, quantity, "Inventory is not loaded"
	end

	local added, remaining, message = self:AddItemToInventory(inventory, itemId, quantity, metadata)
	if added then
		self.InventoryChanged:Fire(player, self:GetInventory(player))
	end

	return added, remaining, message
end

function InventoryService:RemoveItem(player, itemId, quantity)
	local inventory = self:GetLiveInventory(player)
	local requested = math.floor(tonumber(quantity) or 0)
	local remaining = requested

	if not inventory then
		return false, quantity, "Inventory is not loaded"
	end

	if remaining <= 0 then
		return false, remaining, "Quantity must be positive"
	end

	for index = #inventory.Slots, 1, -1 do
		local slot = inventory.Slots[index]
		if slot.ItemId == itemId and remaining > 0 then
			local amountToRemove = math.min(slot.Quantity, remaining)
			slot.Quantity -= amountToRemove
			remaining -= amountToRemove

			if slot.Quantity <= 0 then
				table.remove(inventory.Slots, index)
			end
		end
	end

	local removed = remaining < requested
	if removed then
		inventory.UpdatedAt = os.time()
		self.InventoryChanged:Fire(player, self:GetInventory(player))
	end

	return removed, remaining, remaining == 0 and nil or "Not enough items"
end

function InventoryService:MoveSlot(player, fromSlotId, toIndex)
	local inventory = self:GetLiveInventory(player)
	if not inventory then
		return false, "Inventory is not loaded"
	end

	toIndex = math.floor(tonumber(toIndex) or 0)
	if toIndex < 1 or toIndex > inventory.MaxSlots then
		return false, "Target slot is out of range"
	end

	local fromIndex
	for index, slot in ipairs(inventory.Slots) do
		if slot.SlotId == fromSlotId then
			fromIndex = index
			break
		end
	end

	if not fromIndex then
		return false, "Source slot was not found"
	end

	local slot = table.remove(inventory.Slots, fromIndex)
	table.insert(inventory.Slots, math.min(toIndex, #inventory.Slots + 1), slot)
	inventory.UpdatedAt = os.time()
	self.InventoryChanged:Fire(player, self:GetInventory(player))
	return true, nil
end

return InventoryService
