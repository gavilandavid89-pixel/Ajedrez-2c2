# V101 — Entrada exclusivamente táctil

## Cambios
- La partida acepta eventos `InputEventScreenTouch` para seleccionar casillas y mover piezas.
- Se mantiene el gesto táctil de pulsar origen y destino, además de arrastrar desde origen hasta destino.
- Se eliminaron ramas de entrada de ratón y la lógica de deduplicación Touch + Mouse emulado.
- El desplazamiento manual del panel de sugerencias y el cierre de superposiciones usan gestos táctiles.
- El desplazamiento manual de la cuenta usa exclusivamente toque/arrastre; los `Control` de Godot conservan sus filtros de propagación porque también afectan a eventos táctiles.
- Los tests de entrada ahora simulan pantalla táctil y fijan los roles del tablero para que las pruebas no dependan de la asignación aleatoria de equipos.
- La auditoría de retos 2c2 ahora verifica que los cuatro participantes queden registrados y que la partida espere a que se asignen explícitamente los equipos.

## Validación con Godot 4.7.2
- Importación del proyecto: correcta, sin errores de análisis de scripts.
- Suite principal: 39/39.
- Regresión de movimiento y bots: 18/18.
- Regresión de interfaz: 53/53.
- Estabilidad: 17/17.
- Auditoría de consistencia: 19/19.
- Arranque headless de la escena principal: correcto.

## Alcance
El proyecto queda orientado a interacción táctil Android. Los botones estándar de Godot siguen siendo `Control` normales para conservar el comportamiento táctil. No se ha generado todavía un APK de lanzamiento ni se ha probado en un dispositivo Android físico.
