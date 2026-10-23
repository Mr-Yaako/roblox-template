-- Qué hace cada objeto de GameConfig.ShopItems. Se llama cada vez que aparece el personaje
-- y justo después de comprarlo.

local function getHumanoid(character: Model): Humanoid?
	return character:WaitForChild("Humanoid", 5) :: Humanoid?
end

local ItemEffects: { [string]: (player: Player, character: Model) -> () } = {
	SpeedBoots = function(_player, character)
		local humanoid = getHumanoid(character)
		if humanoid then
			humanoid.WalkSpeed += 8
		end
	end,

	JumpBoost = function(_player, character)
		local humanoid = getHumanoid(character)
		if humanoid then
			humanoid.UseJumpPower = true
			humanoid.JumpPower += 20
		end
	end,
}

return ItemEffects
