# Ajedrez 2c2 — V50: entrada táctil y sugerencias

## Problemas corregidos

### 1. Touch + Mouse emulado
Android puede entregar un `InputEventScreenTouch` y además un `InputEventMouseButton` emulado. La partida mantiene una ventana de deduplicación para que ambos eventos no vuelvan a seleccionar/mover la pieza.

### 2. Movimiento en un solo gesto
Se mantiene el modo de toque origen → destino, pero ahora también se verifica explícitamente el gesto táctil de arrastrar: tocar una pieza, mover el dedo y soltar sobre la casilla destino ejecuta la jugada en un solo gesto.

### 3. Sugerir sin selección previa
El botón **Sugerir** ya no exige seleccionar una pieza. Si hay una pieza seleccionada respeta esa intención; si no, calcula una jugada legal mediante el controlador de bots y la propone al compañero.

## Pruebas

- Movimiento/bots: **22/22 OK**.
- Sugerencia del bot: **6/6 OK**.
- Suite principal Godot 4.7.2: **39/39 OK**.
- Se verificó Touch + Mouse emulado sin toque adicional.
- Se verificó arrastre táctil en un solo gesto.
- Se verificó Sugerir sin seleccionar previamente una pieza.

## Nota Android
Estas pruebas son ejecuciones reales de Godot 4.7.2 en el entorno de pruebas, incluyendo eventos táctiles emulados. No sustituyen una prueba física en el teléfono Android.
