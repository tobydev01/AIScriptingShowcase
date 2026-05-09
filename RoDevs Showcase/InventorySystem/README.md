# Inventory System

A modular Roblox inventory framework with server-authoritative item storage, DataStore persistence, configurable item definitions, and stack-aware add/remove behavior.

## Folder Layout

- `ReplicatedStorage/InventoryFramework/Modules/ItemDefinitions.lua` stores item metadata and max stack sizes.
- `ReplicatedStorage/InventoryFramework/Modules/InventoryConfig.lua` stores datastore name, autosave interval, max slots, and starter items.
- `ReplicatedStorage/InventoryFramework/Modules/InventoryDataStore.lua` wraps Roblox DataStore reads/writes.
- `ReplicatedStorage/InventoryFramework/Modules/InventoryService.lua` owns inventory validation, item stacking, slot moves, and player lifecycle persistence helpers.
- `ServerScriptService/InventoryFramework/InventoryServer.lua` connects players, remotes, autosave, and shutdown saving.
- `StarterPlayerScripts/InventoryFramework/InventoryClient.lua` provides a lightweight client API for UI scripts.

## Setup

1. Create the `InventoryFramework` folder in `ReplicatedStorage` with the module, `RemoteEvents`, and `RemoteFunctions` children shown above.
2. Replace the `.txt` placeholders with Roblox instances named `InventoryUpdated`, `InventoryAction`, and `GetInventory`.
3. Put `InventoryServer.lua` under `ServerScriptService/InventoryFramework`.
4. Put `InventoryClient.lua` under `StarterPlayerScripts/InventoryFramework` or require it from your own UI controller.
5. Enable Studio API access for DataStores when testing in Studio.

## Server Usage

```lua
local InventoryService = require(ReplicatedStorage.InventoryFramework.Modules.InventoryService)

InventoryService:AddItem(player, "wood", 15)
InventoryService:RemoveItem(player, "health_potion", 1)
```

`AddItem` fills existing stacks first, then opens new stacks up to `InventoryConfig.MaxSlots`. Any quantity that cannot fit is returned as `remaining`.
