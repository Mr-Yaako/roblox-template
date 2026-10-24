-- Crea la carpeta leaderstats (la tabla de jugadores de Roblox) y la mantiene al día.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local LeaderstatsService = {}

function LeaderstatsService.Start()
	DataService.OnProfileLoaded(function(player, profile)
		local folder = Instance.new("Folder")
		folder.Name = "leaderstats"

		for _, key in GameConfig.Leaderstats do
			local value = Instance.new("IntValue")
			value.Name = key
			value.Value = profile.Data[key] or 0
			value.Parent = folder
		end

		folder.Parent = player
	end)

	for _, key in GameConfig.Leaderstats do
		DataService.OnChanged(key, function(player, newValue)
			local folder = player:FindFirstChild("leaderstats")
			local value = folder and folder:FindFirstChild(key)
			if value then
				value.Value = newValue
			end
		end)
	end
end

return LeaderstatsService
