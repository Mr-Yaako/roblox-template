-- Carga y guarda los datos de cada jugador con ProfileStore (con bloqueo de sesión, para que
-- dos servidores no escriban los mismos datos a la vez y no se dupliquen cosas).
-- Los demás servicios deben cambiar datos con Set/Increment para que se avise del cambio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local DataTemplate = require(script.Parent.Parent.DataTemplate)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

type Callback = (player: Player, ...any) -> ()

local DataService = {}

local store = ProfileStore.New(GameConfig.DataStoreName, DataTemplate)
if RunService:IsStudio() and GameConfig.UseMockDataInStudio then
	store = store.Mock
end

local profiles: { [Player]: any } = {}
local loadedCallbacks: { Callback } = {}
local changedCallbacks: { [string]: { Callback } } = {}

local function fireChanged(player: Player, key: string, value: any)
	for _, callback in changedCallbacks[key] or {} do
		task.spawn(callback, player, value)
	end
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- Falló DataStore o el jugador salió mientras cargaba.
		if player.Parent == Players then
			player:Kick(GameConfig.Text.DataLoadFailed)
		end
		return
	end

	profile:AddUserId(player.UserId) -- requerido para solicitudes de borrado de datos (GDPR)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		if player.Parent == Players then
			player:Kick(GameConfig.Text.SessionEnded)
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	profiles[player] = profile
	for _, callback in loadedCallbacks do
		task.spawn(callback, player, profile)
	end
end

-- Perfil activo del jugador, o nil si todavía no carga.
function DataService.GetProfile(player: Player): any?
	return profiles[player]
end

-- Espera a que cargue el perfil. Devuelve nil si el jugador se va antes.
function DataService.WaitForProfile(player: Player): any?
	while player.Parent == Players do
		local profile = profiles[player]
		if profile then
			return profile
		end
		task.wait()
	end
	return nil
end

function DataService.Get(player: Player, key: string): any
	local profile = profiles[player]
	return profile and profile.Data[key]
end

function DataService.Set(player: Player, key: string, value: any): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	profile.Data[key] = value
	fireChanged(player, key, value)
	return true
end

function DataService.Increment(player: Player, key: string, delta: number): number?
	local profile = profiles[player]
	if not profile then
		return nil
	end
	local value = (profile.Data[key] or 0) + delta
	profile.Data[key] = value
	fireChanged(player, key, value)
	return value
end

-- Llama a callback(player, profile) cuando carga un perfil (también para los ya cargados).
function DataService.OnProfileLoaded(callback: Callback)
	table.insert(loadedCallbacks, callback)
	for player, profile in profiles do
		task.spawn(callback, player, profile)
	end
end

-- Llama a callback(player, newValue) cuando Set/Increment cambian ese campo.
function DataService.OnChanged(key: string, callback: Callback)
	changedCallbacks[key] = changedCallbacks[key] or {}
	table.insert(changedCallbacks[key], callback)
end

function DataService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			profile:EndSession()
		end
	end)
	-- ProfileStore ya guarda y cierra sesiones al apagar el servidor (BindToClose).
end

return DataService
