local DataStoreService = game:GetService("DataStoreService")

local InventoryConfig = require(script.Parent.InventoryConfig)

local InventoryDataStore = {}
local inventoryStore = DataStoreService:GetDataStore(InventoryConfig.DataStoreName)

local function getPlayerKey(player)
	return ("Player_%d"):format(player.UserId)
end

function InventoryDataStore:Load(player)
	local key = getPlayerKey(player)
	local ok, data = pcall(function()
		return inventoryStore:GetAsync(key)
	end)

	if ok then
		print(("[InventoryDataStore] Loaded inventory for %s"):format(player.Name))
		return data
	end

	warn(("[InventoryDataStore] Failed to load inventory for %s: %s"):format(player.Name, tostring(data)))
	return nil
end

function InventoryDataStore:Save(player, inventory)
	local key = getPlayerKey(player)
	local ok, err = pcall(function()
		inventoryStore:SetAsync(key, inventory)
	end)

	if ok then
		print(("[InventoryDataStore] Saved inventory for %s"):format(player.Name))
		return true
	end

	warn(("[InventoryDataStore] Failed to save inventory for %s: %s"):format(player.Name, tostring(err)))
	return false
end

function InventoryDataStore:Update(player, updateCallback)
	local key = getPlayerKey(player)
	local ok, result = pcall(function()
		return inventoryStore:UpdateAsync(key, updateCallback)
	end)

	if ok then
		return true, result
	end

	warn(("[InventoryDataStore] Failed to update inventory for %s: %s"):format(player.Name, tostring(result)))
	return false, nil
end

return InventoryDataStore
