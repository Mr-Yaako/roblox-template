-- Tienda con la moneda del juego. El cliente solo pide "quiero X"; el servidor valida todo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local ItemEffects = require(script.Parent.Parent.ItemEffects)
local RateLimit = require(script.Parent.Parent.Util.RateLimit)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ShopService = {}

local purchaseLimit = RateLimit.new(0.5)

local function applyItem(player: Player, itemId: string)
	local effect = ItemEffects[itemId]
	local character = player.Character
	if effect and character then
		task.spawn(effect, player, character)
	end
end

local function owns(player: Player, itemId: string): boolean
	local owned = DataService.Get(player, "OwnedItems")
	return owned ~= nil and owned[itemId] == true
end

local function purchase(player: Player, itemId: unknown): (boolean, string?)
	if typeof(itemId) ~= "string" or not purchaseLimit:Check(player) then
		return false, nil
	end

	local item = GameConfig.ShopItems[itemId]
	if not item or not DataService.GetProfile(player) then
		return false, nil
	end
	if owns(player, itemId) then
		return false, GameConfig.Text.Owned
	end
	if not CurrencyService.Spend(player, item.Price) then
		return false, GameConfig.Text.NotEnoughCurrency
	end

	local owned = table.clone(DataService.Get(player, "OwnedItems"))
	owned[itemId] = true
	DataService.Set(player, "OwnedItems", owned)
	player:SetAttribute("Owns_" .. itemId, true)
	applyItem(player, itemId)

	return true, nil
end

function ShopService.Start()
	Remotes.Function("PurchaseItem").OnServerInvoke = purchase

	DataService.OnProfileLoaded(function(player, profile)
		for itemId in profile.Data.OwnedItems do
			player:SetAttribute("Owns_" .. itemId, true)
		end

		local function onCharacter()
			for itemId in DataService.Get(player, "OwnedItems") or {} do
				applyItem(player, itemId)
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

return ShopService
