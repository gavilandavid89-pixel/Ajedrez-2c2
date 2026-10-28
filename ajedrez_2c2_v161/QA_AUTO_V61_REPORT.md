# QA automático V61

Fecha: 2026-10-04
Godot: 4.7.2 stable

## Resultado

- Editor/importación: PASS
- Runner núcleo: 39/39
- Movimiento + bots: 21/21
- Bots dificultad: 39/39
- Integración bots: 6/6
- Competitivo: 34/34
- UI regression: 53/53
- Responsive touch: 30/30
- Menú responsive: 37/37
- Orientación/layout actual: 22/22
- Navegación: 17/17
- Perfil: 9/9
- Account Hub: 144/144
- Storage: 18/18
- Runtime safety: 4/4
- Tandas 5-7: 23/23
- Tanda 9 estabilidad: 19/19
- Matchmaking: 8/8
- Online setup: 37/37
- Match history: 5/5
- Replay móvil: 10/10
- Sugerencias V50: 19/19
- 1c1 progresión: 5/5
- 1c1 presentación: 5/5
- Board First HUD: 42/42
- HUD V59: 25/25
- Orientación/chat/acciones V60: 15/15
- Sugerencia compacta V61: 22/22
- Tanda 8 stress: 5352/5352

## Correcciones de QA

Las suites V58-V61 tenían tipado de test insuficiente al instanciar `game.tscn`: inferían `Control` y accedían a propiedades del controlador. Se tiparon contra `scenes/game.gd` para que errores reales no fueran ocultados por el harness.

V22 contenía expectativas antiguas (columnas laterales de 220-300 px y tarjetas grandes) incompatibles con el diseño Board First actual. Se actualizaron a invariantes actuales: laterales utilizables, tarjetas compactas legibles y controles completamente dentro del viewport.

## Pendientes / no falsificados

- `engine_review_integration_tests.gd` ejecutado como suite aislada no terminó dentro del timeout; no se marca como PASS aislado. La integración equivalente dentro de `tests/run_tests.gd` pasa.
- El smoke runtime permanece vivo por diseño; fue terminado por timeout después de comprobar arranque OpenGL y ausencia de errores de script. No se considera fallo de la aplicación.
- Hay warnings de `ObjectDB leaked` en algunos tests de estrés/UI al cerrar; no provocaron aserciones fallidas.
- ALSA no tiene dispositivo de audio en el entorno de laboratorio; Godot cae al driver dummy.
