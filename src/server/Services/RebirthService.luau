-- Renacer: reinicia las monedas (y las mejoras, si GameConfig.Rebirth.ResetUpgrades) a cambio de
-- un multiplicador permanente de monedas. Cada renacimiento cuesta más que el anterior.
-- Si tu juego pide algo más que monedas (p. ej. llegar a cierta zona), regístralo con AddRequirement.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local RateLimit = require(script.Parent.Parent.Util.RateLimit)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Progression = require(ReplicatedStorage.Shared.Progression)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

type Requirement = (player: Player) -> (boolean, string?)

local KEY = "Rebirths"

local RebirthService = {}

local rebirthLimit = RateLimit.new(1)
local requirements: { Requirement } = {}

-- check(player) devuelve true si cumple, o false y el mensaje que verá el jugador.
function RebirthService.AddRequirement(check: Requirement)
	table.insert(requirements, check)
end

function RebirthService.GetRebirths(player: Player): number
	return DataService.Get(player, KEY) or 0
end

local function rebirth(player: Player): (boolean, string?)
	if not GameConfig.Rebirth.Enabled or not rebirthLimit:Check(player) then
		return false, nil
	end
	if not DataService.GetProfile(player) then
		return false, nil
	end

	for _, check in requirements do
		local ok, message = check(player)
		if not ok then
			return false, message
		end
	end

	local price = Progression.RebirthPrice(RebirthService.GetRebirths(player))
	if CurrencyService.Get(player) < price then
		return false, GameConfig.Text.NotEnoughCurrency
	end

	DataService.Set(player, GameConfig.Currency.Key, GameConfig.Currency.Starting)
	if GameConfig.Rebirth.ResetUpgrades then
		DataService.Set(player, "UpgradeLevels", {})
	end
	DataService.Increment(player, KEY, 1)

	return true, nil
end

function RebirthService.Start()
	Remotes.Function("Rebirth").OnServerInvoke = rebirth

	-- El cliente lee el atributo para mostrar el precio del siguiente renacimiento.
	DataService.OnProfileLoaded(function(player, profile)
		player:SetAttribute(KEY, profile.Data[KEY])
	end)
	DataService.OnChanged(KEY, function(player, value)
		player:SetAttribute(KEY, value)
	end)

	Players.PlayerRemoving:Connect(function(player)
		rebirthLimit:Remove(player)
	end)
end

return RebirthService
