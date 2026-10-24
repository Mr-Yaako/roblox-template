-- Game passes y developer products. Entrega lo comprado de forma segura:
--  * Los recibos solo se marcan como entregados después de guardar el perfil, así nadie paga
--    sin recibir lo comprado aunque el servidor se caiga.
--  * Cada recibo se entrega una sola vez (PurchaseIdCache).
-- Las compras solo las inicia el jugador con un botón; este servicio nunca abre ventanas de compra.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PURCHASE_ID_CACHE_SIZE = 100
local SAVE_RETRY_SECONDS = 10

local MonetizationService = {}

local ownedPasses: { [Player]: { [string]: boolean } } = {}
local passNameById: { [number]: string } = {}
local productNameById: { [number]: string } = {}

for name, pass in GameConfig.GamePasses do
	if pass.Id ~= 0 then
		passNameById[pass.Id] = name
	end
end
for name, product in GameConfig.DevProducts do
	if product.Id ~= 0 then
		productNameById[product.Id] = name
	end
end

local function setPassOwned(player: Player, name: string)
	ownedPasses[player] = ownedPasses[player] or {}
	ownedPasses[player][name] = true
	player:SetAttribute("Pass_" .. name, true) -- el cliente lo lee para la UI
end

local function loadPasses(player: Player)
	for id, name in passNameById do
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
		if not ok then
			warn(`[Monetization] No se pudo revisar el pase {name} de {player.Name}: {owns}`)
		elseif owns then
			setPassOwned(player, name)
		end
	end
end

local function grantProduct(player: Player, product)
	for key, amount in product.Grant do
		if DataService.Increment(player, key, amount) == nil then
			error(`perfil de {player.Name} no disponible`)
		end
	end
end

-- Patrón recomendado por ProfileStore para ProcessReceipt.
local function purchaseIdCheckAsync(profile, purchaseId: string, grant: () -> ()): Enum.ProductPurchaseDecision
	if not profile:IsActive() then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local cache = profile.Data.PurchaseIdCache
	if not table.find(cache, purchaseId) then
		local ok, err = pcall(grant)
		if not ok then
			warn(`[Monetization] Falló la entrega del recibo {purchaseId}: {err}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		while #cache >= PURCHASE_ID_CACHE_SIZE do
			table.remove(cache, 1)
		end
		table.insert(cache, purchaseId)
	end

	local function isSaved(): boolean
		local saved = profile.LastSavedData and profile.LastSavedData.PurchaseIdCache
		return saved ~= nil and table.find(saved, purchaseId) ~= nil
	end

	if isSaved() then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	while profile:IsActive() do
		local lastSaved = profile.LastSavedData
		profile:Save()
		if profile.LastSavedData == lastSaved then
			profile.OnAfterSave:Wait()
		end
		if isSaved() then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		if profile:IsActive() then
			task.wait(SAVE_RETRY_SECONDS)
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function processReceipt(receiptInfo): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Roblox reintenta cuando el jugador vuelva a entrar.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local name = productNameById[receiptInfo.ProductId]
	if not name then
		warn(`[Monetization] Producto desconocido {receiptInfo.ProductId}; agrégalo a GameConfig.DevProducts`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = DataService.WaitForProfile(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return purchaseIdCheckAsync(profile, receiptInfo.PurchaseId, function()
		grantProduct(player, GameConfig.DevProducts[name])
	end)
end

function MonetizationService.HasPass(player: Player, name: string): boolean
	local passes = ownedPasses[player]
	return passes ~= nil and passes[name] == true
end

-- El multiplicador más alto entre los pases que tiene el jugador (1 si ninguno).
function MonetizationService.GetCoinMultiplier(player: Player): number
	local multiplier = 1
	for name, pass in GameConfig.GamePasses do
		if pass.CoinMultiplier and MonetizationService.HasPass(player, name) then
			multiplier = math.max(multiplier, pass.CoinMultiplier)
		end
	end
	return multiplier
end

function MonetizationService.Start()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local name = passNameById[passId]
		if purchased and name then
			setPassOwned(player, name)
		end
	end)

	Players.PlayerAdded:Connect(loadPasses)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPasses, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		ownedPasses[player] = nil
	end)
end

return MonetizationService
