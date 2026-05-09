local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryFramework = ReplicatedStorage:WaitForChild("InventoryFramework")
local Remotes = InventoryFramework:WaitForChild("RemoteEvents")
local Functions = InventoryFramework:WaitForChild("RemoteFunctions")

local InventoryUpdated = Remotes:WaitForChild("InventoryUpdated")
local InventoryAction = Remotes:WaitForChild("InventoryAction")
local GetInventory = Functions:WaitForChild("GetInventory")

local InventoryClient = {}
InventoryClient.Inventory = nil
InventoryClient.Changed = Instance.new("BindableEvent")

local function setInventory(inventory)
	InventoryClient.Inventory = inventory
	InventoryClient.Changed:Fire(inventory)
end

function InventoryClient:Start()
	local inventory = GetInventory:InvokeServer()
	setInventory(inventory)
end

function InventoryClient:GetInventory()
	return self.Inventory
end

function InventoryClient:MoveSlot(slotId, toIndex)
	InventoryAction:FireServer({
		Action = "MoveSlot",
		SlotId = slotId,
		ToIndex = toIndex,
	})
end

function InventoryClient:UseItem(itemId)
	InventoryAction:FireServer({
		Action = "UseItem",
		ItemId = itemId,
	})
end

InventoryUpdated.OnClientEvent:Connect(setInventory)

InventoryClient:Start()
return InventoryClient
