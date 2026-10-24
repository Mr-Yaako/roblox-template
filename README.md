# roblox-template

Plantilla para hacer juegos sencillos de Roblox (obbies, tycoons, simuladores) sin empezar de cero cada vez. El código vive en este repo y se sincroniza a Roblox Studio con Rojo; el mapa y los modelos se construyen en Studio.

## Qué trae

| Sistema | Archivo | Qué hace |
| --- | --- | --- |
| Datos del jugador | `src/server/Services/DataService.luau` | Guarda y carga con [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) (bloqueo de sesión, sin duplicados). |
| Leaderstats | `src/server/Services/LeaderstatsService.luau` | Muestra en la tabla de jugadores los campos de `GameConfig.Leaderstats`. |
| Moneda | `src/server/Services/CurrencyService.luau` | `Add` / `Spend` / `Get`, con multiplicador de game pass. |
| Tienda | `src/server/Services/ShopService.luau` + `src/client/Controllers/ShopController.luau` | Objetos que se compran con la moneda del juego; el servidor valida todo. |
| Mejoras por nivel | `src/server/Services/UpgradeService.luau` | Mejoras que se compran varias veces, cada nivel más caro (`GameConfig.Upgrades`). Efectos en `src/server/UpgradeEffects.luau`. |
| Renacer | `src/server/Services/RebirthService.luau` | Reinicia monedas y mejoras a cambio de un bono permanente de monedas (`GameConfig.Rebirth`). Requisitos extra con `RebirthService.AddRequirement`. |
| Robux | `src/server/Services/MonetizationService.luau` | Game passes y developer products con entrega segura de recibos. |

Todo lo que cambia entre juegos está en `src/shared/GameConfig.luau`, `src/server/DataTemplate.luau`, `src/server/ItemEffects.luau` y `src/server/UpgradeEffects.luau`. Si un juego no usa mejoras o renacer, deja `GameConfig.Upgrades = {}` y `GameConfig.Rebirth.Enabled = false`.

## Instalación en Windows (una sola vez)

1. Instala [Git para Windows](https://git-scm.com/download/win) y [Visual Studio Code](https://code.visualstudio.com/).
2. Instala el gestor de herramientas. Se recomienda [Rokit](https://github.com/rojo-rbx/rokit), el sucesor de Aftman (Aftman ya no recibe mantenimiento). Ambos leen `aftman.toml`. En PowerShell:

   ```powershell
   Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
   ```

   Cierra y vuelve a abrir la terminal para que `rokit` quede en el PATH. Si prefieres Aftman, descarga `aftman.exe` de sus [releases](https://github.com/LPGhatguy/aftman/releases) y ejecuta `aftman self-install`.
3. Clona el repo e instala las herramientas fijadas en `aftman.toml` (Rojo, Wally, Selene, StyLua):

   ```powershell
   git clone https://github.com/Mr-Yaako/roblox-template.git
   cd roblox-template
   rokit install   # o: aftman install
   ```

4. Descarga los paquetes de Wally (crea la carpeta `ServerPackages`):

   ```powershell
   wally install
   ```

5. Instala el plugin de Rojo en Studio:

   ```powershell
   rojo plugin install
   ```

6. Abre la carpeta en VS Code y acepta las extensiones recomendadas (Luau LSP, StyLua, Selene, Rojo).

## Uso diario

1. En la carpeta del proyecto: `rojo serve`
2. En Roblox Studio abre tu lugar, ve a la pestaña **Plugins → Rojo → Connect**.
3. Edita el código en VS Code; Studio se actualiza solo. El mapa se construye directamente en Studio (Rojo no toca `Workspace`).
4. Antes de hacer commit:

   ```powershell
   stylua src
   selene src
   ```

Para que Studio pueda guardar datos reales, activa **Game Settings → Security → Enable Studio Access to API Services**. Mientras `GameConfig.UseMockDataInStudio` sea `true`, Studio usa datos falsos y no ensucia el DataStore real.

## Crear un juego nuevo con la plantilla

1. En GitHub usa **Use this template** (actívalo en Settings → General → Template repository) o copia la carpeta.
2. Cambia `GameConfig.DataStoreName` si dos juegos comparten universo; si no, cada experiencia tiene su propio DataStore.
3. Edita `GameConfig.luau`: moneda, leaderstats, objetos de la tienda, game passes y productos.
4. Agrega los campos nuevos a `DataTemplate.luau` y los efectos de los objetos a `ItemEffects.luau`.
5. Escribe la lógica del juego como un servicio nuevo en `src/server/Services/` y agrégalo a `START_ORDER` en `src/server/Main.server.luau`. Ejemplo para dar monedas al tocar una parte:

   ```lua
   local CurrencyService = require(script.Parent.CurrencyService)

   workspace.Coin.Touched:Connect(function(hit)
   	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
   	if player then
   		CurrencyService.Add(player, 10)
   	end
   end)
   ```

## Game passes y developer products

1. Publica el lugar y crea el pase o producto en el [Creator Dashboard](https://create.roblox.com/dashboard/creations) → tu experiencia → **Monetization**.
2. Copia su Id a `GameConfig.GamePasses` o `GameConfig.DevProducts`. Los que tengan `Id = 0` se ignoran.
3. Los precios en Robux se leen de Roblox y se muestran en la tienda antes de comprar.

Los developer products solo se marcan como entregados después de guardar el perfil, así que si el servidor falla Roblox reintenta la entrega y nadie pierde Robux.

## Reglas de monetización

El público son niños, así que la plantilla está pensada para cumplir las [reglas de la comunidad de Roblox](https://en.help.roblox.com/hc/articles/203313410) y no meterse en problemas de moderación:

- Las ventanas de compra solo se abren cuando el jugador presiona un botón; nunca de forma automática ni con temporizadores.
- El precio real se muestra antes de comprar. No uses textos como "GRATIS" en algo que cuesta Robux.
- Nada de cajas o premios aleatorios pagados con Robux sin mostrar las probabilidades (Roblox lo exige).
- Lo que se vende con Robux debe hacer lo que dice la descripción.

## Estructura

```
src/
  client/            -> StarterPlayer.StarterPlayerScripts.Client
    Main.client.luau
    Controllers/
  server/            -> ServerScriptService.Server
    Main.server.luau
    DataTemplate.luau
    ItemEffects.luau
    Services/
    Util/
  shared/            -> ReplicatedStorage.Shared
    GameConfig.luau
    Remotes.luau
ServerPackages/      -> ServerScriptService.ServerPackages (Wally, no se sube a git)
```

Para agregar paquetes compartidos de Wally (cliente y servidor), ponlos en `[dependencies]` de `wally.toml`, ejecuta `wally install` y agrega `"Packages": { "$path": "Packages" }` dentro de `ReplicatedStorage` en `default.project.json`.
