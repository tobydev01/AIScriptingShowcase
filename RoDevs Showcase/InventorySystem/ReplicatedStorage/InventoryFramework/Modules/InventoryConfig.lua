local InventoryConfig = {
	DataStoreName = "InventoryFramework_v1",
	AutoSaveInterval = 120,
	MaxSlots = 30,
	DefaultInventory = {
		{ ItemId = "health_potion", Quantity = 3 },
		{ ItemId = "wood", Quantity = 25 },
	},
}

return InventoryConfig
