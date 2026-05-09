local ItemDefinitions = {
	health_potion = {
		DisplayName = "Health Potion",
		Description = "Restores a small amount of health.",
		Category = "Consumable",
		MaxStack = 10,
		Tradable = true,
	},
	mana_potion = {
		DisplayName = "Mana Potion",
		Description = "Restores a small amount of mana.",
		Category = "Consumable",
		MaxStack = 10,
		Tradable = true,
	},
	wood = {
		DisplayName = "Wood",
		Description = "Basic crafting material gathered from trees.",
		Category = "Material",
		MaxStack = 99,
		Tradable = true,
	},
	iron_ore = {
		DisplayName = "Iron Ore",
		Description = "A rugged ore used by smiths.",
		Category = "Material",
		MaxStack = 50,
		Tradable = true,
	},
	bronze_sword = {
		DisplayName = "Bronze Sword",
		Description = "A starter blade that cannot stack.",
		Category = "Weapon",
		MaxStack = 1,
		Tradable = false,
	},
}

function ItemDefinitions:Get(itemId)
	return self[itemId]
end

function ItemDefinitions:GetMaxStack(itemId)
	local definition = self:Get(itemId)
	if not definition then
		return nil
	end

	return math.max(1, definition.MaxStack or 1)
end

function ItemDefinitions:IsValid(itemId)
	return self:Get(itemId) ~= nil
end

return ItemDefinitions
