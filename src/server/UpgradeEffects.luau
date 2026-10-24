-- Qué hace cada mejora de GameConfig.Upgrades sobre el personaje. Se llama cada vez que aparece
-- el personaje y cada vez que cambia el nivel, con el valor del nivel actual. Pon el valor
-- absoluto (no lo sumes), porque se vuelve a llamar en cada cambio.
-- Las mejoras que no tocan el personaje (p. ej. capacidad de mochila) no necesitan entrada aquí:
-- tus servicios leen el valor con UpgradeService.GetValue.

local function getHumanoid(character: Model): Humanoid?
	return character:WaitForChild("Humanoid", 5) :: Humanoid?
end

local UpgradeEffects: { [string]: (player: Player, character: Model, value: any) -> () } = {
	MaxHealth = function(_player, character, value)
		local humanoid = getHumanoid(character)
		if humanoid then
			humanoid.MaxHealth = value
			humanoid.Health = value
		end
	end,
}

return UpgradeEffects
