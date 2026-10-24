-- Tienda básica generada desde GameConfig. Es un punto de partida: reemplázala por una UI hecha
-- en Studio cuando el juego lo amerite. Los precios en Robux se muestran antes de comprar y la
-- ventana de compra de Roblox solo se abre cuando el jugador presiona el botón.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Progression = require(ReplicatedStorage.Shared.Progression)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local Text = GameConfig.Text

local ShopController = {}

local function create(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function corner(): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, 8) })
end

local function header(text: string, order: number)
	return create("TextLabel", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	})
end

-- Fila con nombre, descripción, precio y botón. refresh() actualiza el botón según attribute.
-- ownedText es lo que dice el botón cuando attribute es true (por defecto "Ya lo tienes").
local function row(
	order: number,
	title: string,
	description: string,
	attribute: string,
	onBuy: () -> (),
	ownedText: string?
)
	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(130, 36),
		BackgroundColor3 = Color3.fromRGB(46, 160, 67),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.new(1, 1, 1),
	}, { corner() })

	local frame = create("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(45, 45, 55),
	}, {
		corner(),
		create("TextLabel", {
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(1, -160, 0, 22),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = title,
		}),
		create("TextLabel", {
			Position = UDim2.fromOffset(10, 28),
			Size = UDim2.new(1, -160, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(200, 200, 210),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = description,
		}),
		button,
	})

	local priceText = Text.Buy
	local function refresh()
		local owned = player:GetAttribute(attribute) == true
		button.Text = if owned then ownedText or Text.Owned else priceText
		button.AutoButtonColor = not owned
		button.BackgroundColor3 = if owned then Color3.fromRGB(90, 90, 100) else Color3.fromRGB(46, 160, 67)
	end

	button.Activated:Connect(function()
		if player:GetAttribute(attribute) ~= true then
			onBuy()
		end
	end)
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
	refresh()

	return frame, function(newPriceText: string)
		priceText = newPriceText
		refresh()
	end
end

-- Precio real en Robux desde Roblox (no se escribe a mano para que nunca quede desactualizado).
local function fetchRobuxPrice(id: number, infoType: Enum.InfoType, setPrice: (string) -> ())
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		if ok and info and info.PriceInRobux then
			setPrice(`{Text.Robux} {info.PriceInRobux}`)
		end
	end)
end

local function buildList(list: ScrollingFrame, status: TextLabel)
	local purchaseItem = Remotes.Function("PurchaseItem")
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	header(Text.ItemsHeader, nextOrder()).Parent = list
	for itemId, item in GameConfig.ShopItems do
		local frame, setPrice = row(nextOrder(), item.DisplayName, item.Description, "Owns_" .. itemId, function()
			local ok, message = purchaseItem:InvokeServer(itemId)
			status.Text = if ok then "" else message or ""
		end)
		setPrice(`{item.Price} {GameConfig.Currency.Key}`)
		frame.Parent = list
	end

	local purchaseUpgrade = Remotes.Function("PurchaseUpgrade")
	if next(GameConfig.Upgrades) then
		header(Text.UpgradesHeader, nextOrder()).Parent = list
	end
	for upgradeId, upgrade in GameConfig.Upgrades do
		local levelAttribute = "Upgrade_" .. upgradeId
		local maxAttribute = "UpgradeMax_" .. upgradeId
		local frame, setPrice = row(nextOrder(), upgrade.DisplayName, upgrade.Description, maxAttribute, function()
			local ok, message = purchaseUpgrade:InvokeServer(upgradeId)
			status.Text = if ok then "" else message or ""
		end, Text.MaxLevel)

		-- Atributo local (solo en este cliente) para que row() muestre "Nivel máximo".
		local function refreshLevel()
			local level = player:GetAttribute(levelAttribute) or 1
			local price = Progression.UpgradePrice(upgradeId, level)
			player:SetAttribute(maxAttribute, price == nil)
			if price then
				setPrice(`{Text.Level} {level} · {price} {GameConfig.Currency.Key}`)
			end
		end
		player:GetAttributeChangedSignal(levelAttribute):Connect(refreshLevel)
		refreshLevel()
		frame.Parent = list
	end

	if GameConfig.Rebirth.Enabled then
		local rebirth = Remotes.Function("Rebirth")
		header(Text.RebirthHeader, nextOrder()).Parent = list
		local bonus = math.floor(GameConfig.Rebirth.CoinBonusPerRebirth * 100 + 0.5)
		local description = string.format(Text.RebirthDescription, bonus)
		-- Atributo que nunca existe: se puede renacer muchas veces.
		local frame, setPrice = row(nextOrder(), Text.RebirthHeader, description, "_", function()
			local ok, message = rebirth:InvokeServer()
			status.Text = if ok then "" else message or ""
		end)
		local function refreshRebirth()
			local price = Progression.RebirthPrice(player:GetAttribute("Rebirths") or 0)
			setPrice(`{price} {GameConfig.Currency.Key}`)
		end
		player:GetAttributeChangedSignal("Rebirths"):Connect(refreshRebirth)
		refreshRebirth()
		frame.Parent = list
	end

	local hasPasses = false
	for name, pass in GameConfig.GamePasses do
		if pass.Id ~= 0 then
			if not hasPasses then
				header(Text.PassesHeader, nextOrder()).Parent = list
				hasPasses = true
			end
			local frame, setPrice = row(nextOrder(), pass.DisplayName, pass.Description, "Pass_" .. name, function()
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			end)
			fetchRobuxPrice(pass.Id, Enum.InfoType.GamePass, setPrice)
			frame.Parent = list
		end
	end

	local hasProducts = false
	for _, product in GameConfig.DevProducts do
		if product.Id ~= 0 then
			if not hasProducts then
				header(Text.ProductsHeader, nextOrder()).Parent = list
				hasProducts = true
			end
			-- Atributo que nunca existe: los productos se pueden comprar varias veces.
			local frame, setPrice = row(nextOrder(), product.DisplayName, product.Description, "_", function()
				MarketplaceService:PromptProductPurchase(player, product.Id)
			end)
			fetchRobuxPrice(product.Id, Enum.InfoType.Product, setPrice)
			frame.Parent = list
		end
	end
end

function ShopController.Start()
	local status = create("TextLabel", {
		Position = UDim2.new(0, 12, 1, -34),
		Size = UDim2.new(1, -24, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 120, 120),
		Text = "",
	})

	local list = create("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 48),
		Size = UDim2.new(1, -24, 1, -88),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local closeButton = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Size = UDim2.fromOffset(90, 30),
		BackgroundColor3 = Color3.fromRGB(180, 60, 60),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.new(1, 1, 1),
		Text = Text.Close,
	}, { corner() })

	local panel = create("Frame", {
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.6),
		BackgroundColor3 = Color3.fromRGB(30, 30, 38),
	}, {
		corner(),
		create("UISizeConstraint", { MinSize = Vector2.new(320, 300), MaxSize = Vector2.new(560, 520) }),
		create("TextLabel", {
			Position = UDim2.fromOffset(12, 10),
			Size = UDim2.new(1, -120, 0, 30),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 22,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = Text.ShopButton,
		}),
		closeButton,
		list,
		status,
	})

	local openButton = create("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(100, 40),
		BackgroundColor3 = Color3.fromRGB(255, 170, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		Text = Text.ShopButton,
	}, { corner() })

	openButton.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
	closeButton.Activated:Connect(function()
		panel.Visible = false
	end)

	create("ScreenGui", {
		Name = "ShopGui",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	}, { openButton, panel })

	buildList(list, status)
end

return ShopController
