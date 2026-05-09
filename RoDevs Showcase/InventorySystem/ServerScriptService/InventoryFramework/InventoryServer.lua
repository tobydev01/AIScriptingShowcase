local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryFramework = ReplicatedStorage:WaitForChild("InventoryFramework")
local InventoryService = require(InventoryFramework.Modules.InventoryService)
local InventoryConfig = require(InventoryFramework.Modules.InventoryConfig)

local Remotes = InventoryFramework:WaitForChild("RemoteEvents")
local Functions = InventoryFramework:WaitForChild("RemoteFunctions")
local InventoryUpdated = Remotes:WaitForChild("InventoryUpdated")
local InventoryAction = Remotes:WaitForChild("InventoryAction")
local GetInventory = Functions:WaitForChild("GetInventory")

local function sendInventory(player)
	local inventory = InventoryService:GetInventory(player)
	if inventory then
		InventoryUpdated:FireClient(player, inventory)
	end
end

local function handleAction(player, payload)
	if type(payload) ~= "table" then
		return
	end

	local action = payload.Action
	if action == "MoveSlot" then
		local moved, message = InventoryService:MoveSlot(player, payload.SlotId, payload.ToIndex)
		if not moved then
			warn(("[InventoryServer] MoveSlot failed for %s: %s"):format(player.Name, tostring(message)))
		end
	elseif action == "UseItem" then
		local removed, _, message = InventoryService:RemoveItem(player, payload.ItemId, 1)
		if not removed then
			warn(("[InventoryServer] UseItem failed for %s: %s"):format(player.Name, tostring(message)))
		end
	else
		warn(("[InventoryServer] Unknown inventory action from %s: %s"):format(player.Name, tostring(action)))
	end
end

Players.PlayerAdded:Connect(function(player)
	InventoryService:LoadPlayer(player)
	sendInventory(player)
end)

Players.PlayerRemoving:Connect(function(player)
	InventoryService:ReleasePlayer(player)
end)

InventoryAction.OnServerEvent:Connect(handleAction)

GetInventory.OnServerInvoke = function(player)
	return InventoryService:GetInventory(player)
end

InventoryService.InventoryChanged.Event:Connect(function(player, inventory)
	InventoryUpdated:FireClient(player, inventory)
end)

task.spawn(function()
	while true do
		task.wait(InventoryConfig.AutoSaveInterval)
		for _, player in ipairs(Players:GetPlayers()) do
			InventoryService:SavePlayer(player)
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		InventoryService:SavePlayer(player)
	end
end)
