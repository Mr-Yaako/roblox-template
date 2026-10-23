-- Moneda del juego. Úsalo desde tus scripts de juego (p. ej. al tocar una moneda o ganar).
-- Toda la lógica de dinero vive en el servidor: nunca confíes en cantidades que mande el cliente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local KEY = GameConfig.Currency.Key

local CurrencyService = {}

function CurrencyService.Get(player: Player): number
	return DataService.Get(player, KEY) or 0
end

-- Suma monedas ganadas jugando. Aplica multiplicadores de game passes (p. ej. VIP x2).
-- Usa applyMultiplier = false para recompensas fijas que no deben duplicarse.
function CurrencyService.Add(player: Player, amount: number, applyMultiplier: boolean?): number?
	if amount <= 0 then
		return nil
	end
	if applyMultiplier ~= false then
		amount *= MonetizationService.GetCoinMultiplier(player)
	end
	return DataService.Increment(player, KEY, math.floor(amount))
end

-- Cobra monedas. Devuelve false (sin cobrar nada) si no alcanza.
function CurrencyService.Spend(player: Player, amount: number): boolean
	if amount < 0 or CurrencyService.Get(player) < amount then
		return false
	end
	return DataService.Increment(player, KEY, -amount) ~= nil
end

return CurrencyService
