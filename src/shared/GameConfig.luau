-- Configuración de cada juego. Para un juego nuevo, normalmente solo cambias este archivo,
-- server/DataTemplate.luau y server/ItemEffects.luau.

local GameConfig = {}

-- Cambia el nombre (o sube la versión) si cambias el formato de los datos de forma incompatible.
GameConfig.DataStoreName = "PlayerData_v1"

-- En Studio usa datos falsos (no toca el DataStore real). Ponlo en false para probar guardado real.
GameConfig.UseMockDataInStudio = true

GameConfig.Currency = {
	Key = "Coins", -- campo en DataTemplate
	Starting = 0,
}

-- Campos de DataTemplate que se muestran en la tabla de jugadores (máximo 4 en la UI de Roblox).
GameConfig.Leaderstats = { "Coins", "Wins" }

-- Objetos que se compran con la moneda del juego. El efecto vive en server/ItemEffects.luau.
GameConfig.ShopItems = {
	SpeedBoots = {
		DisplayName = "Botas de velocidad",
		Description = "+8 de velocidad al caminar",
		Price = 100,
	},
	JumpBoost = {
		DisplayName = "Súper salto",
		Description = "Saltas más alto",
		Price = 250,
	},
}

-- Mejoras con niveles: se compran varias veces y cada nivel cuesta más. Values[n] es el valor en
-- el nivel n (el nivel 1 es gratis); el precio para subir del nivel n al n+1 es
-- BasePrice * PriceGrowth^(n-1). El efecto vive en server/UpgradeEffects.luau, o léelo desde tus
-- servicios con UpgradeService.GetValue(player, id).
GameConfig.Upgrades = {
	MaxHealth = {
		DisplayName = "Vida máxima",
		Description = "Más vida en cada nivel",
		BasePrice = 50,
		PriceGrowth = 1.8,
		Values = { 100, 125, 150, 175, 200 },
	},
}

-- Renacer: reinicia monedas (y mejoras si ResetUpgrades) a cambio de un bono permanente de monedas.
-- Precio del renacimiento n+1: BasePrice * PriceGrowth^n.
GameConfig.Rebirth = {
	Enabled = true,
	BasePrice = 25000,
	PriceGrowth = 1.5,
	CoinBonusPerRebirth = 0.25, -- +25% de monedas por cada renacimiento, acumulable
	ResetUpgrades = true,
}

-- Game passes (compra única con Robux). Id = 0 significa "aún no creado" y se ignora.
-- Crea el pase en el Creator Dashboard y pega aquí su Id.
GameConfig.GamePasses = {
	VIP = {
		Id = 0,
		DisplayName = "VIP",
		Description = "Ganas el doble de monedas",
		CoinMultiplier = 2,
	},
}

-- Developer products (compras repetibles con Robux). Grant dice qué campos de datos suma.
GameConfig.DevProducts = {
	Coins500 = {
		Id = 0,
		DisplayName = "500 monedas",
		Description = "Paquete de monedas",
		Grant = { Coins = 500 },
	},
}

-- Textos que ve el jugador. Tradúcelos aquí si el juego va para otro idioma.
GameConfig.Text = {
	ShopButton = "Tienda",
	Close = "Cerrar",
	Buy = "Comprar",
	Owned = "Ya lo tienes",
	NotEnoughCurrency = "No tienes suficientes monedas",
	Robux = "R$",
	ItemsHeader = "Objetos",
	PassesHeader = "Pases (Robux)",
	ProductsHeader = "Paquetes (Robux)",
	UpgradesHeader = "Mejoras",
	Level = "Nv",
	MaxLevel = "Nivel máximo",
	RebirthHeader = "Renacer",
	RebirthDescription = "Reinicia monedas y mejoras. +%d%% de monedas para siempre",
	DataLoadFailed = "No se pudieron cargar tus datos. Vuelve a entrar en un momento.",
	SessionEnded = "Tus datos se abrieron en otro servidor. Vuelve a entrar.",
}

return GameConfig
