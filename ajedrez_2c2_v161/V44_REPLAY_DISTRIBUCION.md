# V44 — Distribución Replay

## Distribución final
1. **Movimientos realizados** arriba del tablero, en una tira horizontal compacta y desplazable.
2. **Tablero** debajo, cuadrado y ocupando todo el ancho útil disponible del Replay, sin el margen artificial de 32 px de la versión anterior.
3. **Navegación** abajo del tablero, en una barra fija dentro del Replay con anterior `‹`, posición/movimiento actual y siguiente `›`.

## Comportamiento
- La tira superior sirve para seleccionar directamente una jugada.
- Los botones inferiores sirven para avanzar/retroceder una posición.
- La navegación se desactiva automáticamente en el inicio/final del replay.
- El tablero conserva proporción 1:1.
- En horizontal se limita por el espacio vertical para evitar un tablero incómodo.

## QA
- Revisión estática de orden de nodos y referencias: OK.
- Se preservó la arquitectura existente de replay, estados, movimientos y análisis de motor.
- Este entorno no dispone del ejecutable de Godot 4.7.2, por lo que **no se declara prueba runtime de Godot para V44**. La prueba visual debe hacerse en Godot antes de seguir con otra modificación.
