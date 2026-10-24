-- Forma de los datos guardados de cada jugador. Los campos nuevos se agregan solos a
-- jugadores existentes (Profile:Reconcile). No renombres campos: crea uno nuevo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

return {
	Coins = GameConfig.Currency.Starting,
	Wins = 0,
	OwnedItems = {}, -- [itemId] = true
	UpgradeLevels = {}, -- [upgradeId] = nivel (si falta, es nivel 1)
	Rebirths = 0,
	PurchaseIdCache = {}, -- últimos recibos de developer products ya entregados
}
