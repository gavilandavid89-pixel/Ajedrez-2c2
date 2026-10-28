# Ajedrez 2c2 — V93 Movimiento animado modular

## Objetivo
Evitar que las piezas aparezcan instantáneamente en la casilla destino. El movimiento visual ahora se interpola sobre el tablero y termina con un pequeño sonido de contacto.

## Referencias de diseño consultadas
- Chess.com documenta controles de animación de tablero/movimiento y diferentes tipos de animación; su configuración permite activar/desactivar animaciones de movimiento y elegir efectos de sonido. También existe una opción de animación dinámica, además de la predeterminada.
- Lichess ofrece velocidades de animación de piezas y su comportamiento de movimiento es un deslizamiento visible entre casillas.

Se adoptó una animación tipo "Medium": rápida, suave y legible, evitando efectos llamativos/trazas que puedan distraer durante la partida.

## Implementación
- `ui/components/game/piece_move_animator.gd`: componente modular independiente de las reglas y del estado de ajedrez.
- La lógica de ajedrez sigue actualizando el tablero de inmediato; el animador solo controla la representación visual temporal.
- Movimiento normal: una pieza se desliza de origen a destino con easing suave y un levantamiento visual mínimo.
- Enroque: rey y torre se animan simultáneamente.
- La casilla final se oculta durante el trayecto para evitar duplicar la pieza.
- Al finalizar, el tablero se redibuja y vuelve a mostrar el estado lógico autoritativo.
- Mientras la animación está activa, se bloquean nuevos movimientos de tablero y el coordinador de bots espera a que termine.
- Cambiar/reiniciar la partida cancela cualquier animación anterior para no bloquear el siguiente turno.

## Audio
- `core/services/audio_feedback.gd` añade `move_impact` y `capture_impact`.
- El efecto es generado localmente con un golpe corto y amortiguado, sin depender de un archivo externo.
- El sonido se reproduce **al finalizar** la animación, no al iniciar el movimiento.
- Capturas usan un impacto ligeramente más grave.
- Promociones conservan su sonido secundario después del impacto de aterrizaje.
- El playback se mantiene en el servicio y se libera correctamente para evitar fugas del backend de audio.

## QA ejecutado
- `tests/piece_move_animation_v92_tests.gd`: **13 OK / 0 FALLARON**.
- `tests/movement_bot_regression_tests.gd`: **21/21 OK**.
- `tests/run_modular_architecture_v70.gd`: **62 OK / 0 FALLARON**.
- `tests/full_screen_flow_audit_v87.gd`: **18 OK / 0 FALLARON / 255 interacciones**.
- `tests/ranking_modes_v91_tests.gd`: **6 OK / 0 FALLARON**.
- `tests/run_tests.gd`: **39 OK / 0 FALLARON**.
- Proyecto ejecutado con Godot 4.7.2 real bajo Xvfb y salida visual capturada durante el trayecto y al finalizar.
- La captura final confirmó que el peón termina en e4 y no queda oculto después de terminar la animación.
- El único mensaje de error del entorno gráfico fue `ERR_CANT_OPEN` del backend de audio del contenedor, seguido por fallback al driver de audio dummy; no hubo `SCRIPT ERROR`, `Parse Error`, `Failed loading resource`, `Leaked instance` ni `Orphan` en la ejecución visual final.
- La prueba headless del animador terminó sin fugas después de corregir la liberación del playback de audio.

## Integridad
El ZIP final fue probado con `unzip -t` y posteriormente se ejecutó la prueba principal desde una extracción del **ZIP exacto**, no solo desde el directorio de trabajo.
