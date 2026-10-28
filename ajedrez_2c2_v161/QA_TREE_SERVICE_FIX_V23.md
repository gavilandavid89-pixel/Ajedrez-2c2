# Ajedrez 2c2 v23 — revisión de errores de árbol/servicios

## Problema reportado
`account_hub.gd` podía intentar resolver `/root/PlayerData` cuando el nodo aún no estaba en el árbol activo, provocando errores de `null instance` y `get_node()` con rutas absolutas fuera del SceneTree.

## Correcciones
- Añadido `runtime_services.gd` con acceso seguro a autoloads mediante `Engine.get_main_loop()` + `SceneTree.root`.
- `account_hub.gd` ya no añade un `PlayerData` fallback al root; mantiene un fallback local solo cuando el servicio real no existe.
- `account_hub.gd` desconecta `data_changed` al salir del árbol.
- `board.gd` desconecta `data_changed` al salir del árbol.
- `mode_menu.gd` desconecta `data_changed` al salir del árbol.
- Eliminados todos los accesos absolutos `/root/...` del código y tests activos.
- `game_state.gd` usa `preload()` explícito para `BotData` y `ChessBotController`.
- Corregida la posición de `class_name ChessBoardView` para que Godot 4.7.2 registre correctamente la clase.

## Verificación en Godot 4.7.2
- RuntimeServices safety: **4/4**
- Account Hub: **100/100**
- Movimiento + bots: **18/18**
- Base: **9/9**
- UI regression: **51/51**
- Responsive visual audit: **1504/1504**
- Núcleo: **38/38**
- Storage runtime: **10/10**
- Storage manager: **18/18**
- Tandas 5–7: **23/23**
- Tanda 8: **5357/5357**
- Editor scan Godot 4.7.2: **sin errores de parseo/carga de scripts**
- Búsqueda estática de `get_node/get_node_or_null("/root/...` en `.gd`: **0 coincidencias**

Las advertencias de `ObjectDB leaked at exit` pertenecen a algunos arneses de prueba al destruir el entorno; no hubo fallos de las comprobaciones ni errores de compilación.
