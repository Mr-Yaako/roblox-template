-- Arranca los servicios del servidor. DataService va al final para que los demás
-- ya estén escuchando cuando se cargan los primeros perfiles.

local Services = script.Parent.Services

local START_ORDER = {
	"LeaderstatsService",
	"MonetizationService",
	"CurrencyService",
	"ShopService",
	"DataService",
}

for _, name in START_ORDER do
	local service = require(Services[name])
	if service.Start then
		service.Start()
	end
end
