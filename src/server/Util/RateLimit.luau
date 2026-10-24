-- Limita cuántas veces por segundo un jugador puede usar un remote.

local RateLimit = {}
RateLimit.__index = RateLimit

function RateLimit.new(cooldownSeconds: number)
	return setmetatable({ cooldown = cooldownSeconds, last = {} }, RateLimit)
end

function RateLimit:Check(player: Player): boolean
	local now = os.clock()
	local last = self.last[player]
	if last and now - last < self.cooldown then
		return false
	end
	self.last[player] = now
	return true
end

function RateLimit:Remove(player: Player)
	self.last[player] = nil
end

return RateLimit
