-- Mejoras con niveles: cada compra sube un nivel y el siguiente cuesta más. El nivel 1 es gratis.
-- El cliente solo pide "quiero subir X"; el servidor valida y cobra.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local RateLimit = require(script.Parent.Parent.Util.RateLimit)
local UpgradeEffects = require(script.Parent.Parent.UpgradeEffects)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Progression = require(ReplicatedStorage.Shared.Progression)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local KEY = "UpgradeLevels"

local UpgradeService = {}

local purchaseLimit = RateLimit.new(0.2)

function UpgradeService.GetLevel(player: Player, upgradeId: string): number
	local levels = DataService.Get(player, KEY)
	return levels and levels[upgradeId] or 1
end

-- Valor de la mejora en el nivel actual del jugador (Values[nivel] en GameConfig.Upgrades).
function UpgradeService.GetValue(player: Player, upgradeId: string): any
	return Progression.UpgradeValue(upgradeId, UpgradeService.GetLevel(player, upgradeId))
end

local function applyUpgrade(player: Player, upgradeId: string)
	local effect = UpgradeEffects[upgradeId]
	local character = player.Character
	if effect and character then
		task.spawn(effect, player, character, UpgradeService.GetValue(player, upgradeId))
	end
end

-- Copia los niveles a atributos (el cliente los lee para la UI) y aplica los que cambiaron.
local function sync(player: Player)
	for upgradeId in GameConfig.Upgrades do
		local level = UpgradeService.GetLevel(player, upgradeId)
		if player:GetAttribute("Upgrade_" .. upgradeId) ~= level then
			player:SetAttribute("Upgrade_" .. upgradeId, level)
			applyUpgrade(player, upgradeId)
		end
	end
end

local function purchase(player: Player, upgradeId: unknown): (boolean, string?)
	if typeof(upgradeId) ~= "string" or not purchaseLimit:Check(player) then
		return false, nil
	end
	if not GameConfig.Upgrades[upgradeId] or not DataService.GetProfile(player) then
		return false, nil
	end

	local level = UpgradeService.GetLevel(player, upgradeId)
	local price = Progression.UpgradePrice(upgradeId, level)
	if not price then
		return false, GameConfig.Text.MaxLevel
	end
	if not CurrencyService.Spend(player, price) then
		return false, GameConfig.Text.NotEnoughCurrency
	end

	local levels = table.clone(DataService.Get(player, KEY))
	levels[upgradeId] = level + 1
	DataService.Set(player, KEY, levels)

	return true, nil
end

function UpgradeService.Start()
	Remotes.Function("PurchaseUpgrade").OnServerInvoke = purchase

	-- Cualquier cambio (compra, renacer) pasa por aquí.
	DataService.OnChanged(KEY, sync)

	DataService.OnProfileLoaded(function(player)
		sync(player)

		local function onCharacter()
			for upgradeId in GameConfig.Upgrades do
				applyUpgrade(player, upgradeId)
			end
		end
		player.CharacterAdded:Connect(onCharacter)
		if player.Character then
			onCharacter()
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		purchaseLimit:Remove(player)
	end)
end

return UpgradeService
