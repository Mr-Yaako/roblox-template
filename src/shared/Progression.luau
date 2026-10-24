-- Cálculos de mejoras por nivel y de renacer. Los usan el servidor (para cobrar) y el cliente
-- (para mostrar), así ambos siempre ven el mismo precio.

local GameConfig = require(script.Parent.GameConfig)

local Progression = {}

function Progression.UpgradeMaxLevel(upgradeId: string): number
	return #GameConfig.Upgrades[upgradeId].Values
end

function Progression.UpgradeValue(upgradeId: string, level: number): any
	local values = GameConfig.Upgrades[upgradeId].Values
	return values[math.clamp(level, 1, #values)]
end

-- Precio para subir de `level` a `level + 1`, o nil si ya está al máximo.
function Progression.UpgradePrice(upgradeId: string, level: number): number?
	local upgrade = GameConfig.Upgrades[upgradeId]
	if level >= #upgrade.Values then
		return nil
	end
	return math.floor(upgrade.BasePrice * upgrade.PriceGrowth ^ (level - 1) + 0.5)
end

-- Precio del siguiente renacimiento para alguien que ya renació `rebirths` veces.
function Progression.RebirthPrice(rebirths: number): number
	local rebirth = GameConfig.Rebirth
	return math.floor(rebirth.BasePrice * rebirth.PriceGrowth ^ rebirths + 0.5)
end

-- Multiplicador permanente de monedas por renacimientos (1 si nunca ha renacido).
function Progression.RebirthMultiplier(rebirths: number): number
	return 1 + rebirths * GameConfig.Rebirth.CoinBonusPerRebirth
end

return Progression
