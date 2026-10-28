# Sistema visual móvil — Ajedrez 2c2

## Principio
La interfaz se organiza como un sistema, no como una colección de correcciones aisladas. Cada pantalla debe conservar jerarquía, márgenes, tamaños táctiles y relación espacial consistentes en vertical y horizontal.

## Jerarquía de la partida
1. **Tablero**: foco visual principal, cuadrado, centrado y con margen de seguridad. Las piezas nunca se encogen para dar sitio a elementos decorativos.
2. **Identidad de equipos**: avatares y nombres forman un grupo coherente cerca de las esquinas; el reloj queda unido a ese grupo y no flotando junto al tablero.
3. **Separación**: la cabecera no toca el tablero; movimientos no se superponen con el equipo inferior; la barra de acciones queda separada del grupo del jugador.
4. **Acciones**: controles frecuentes y táctiles abajo; acciones secundarias en menú; botones de navegación nunca se superponen a avatares.

## Tokens de diseño
Los espacios de la partida se centralizan en `core/layout/layout_metrics.gd`: margen exterior, separación cabecera-tablero, separación de movimientos, separación del grupo inferior y barra de acciones. Cambiar el ritmo visual requiere cambiar los tokens, no parchear cada pantalla de manera independiente.

## Adaptación por orientación
- **Vertical**: tablero casi a ancho completo con margen lateral seguro; dos jugadores en línea por equipo; avatares grandes y nombre centrado; reloj pegado al grupo. El grupo superior deja libre el botón de volver.
- **Horizontal**: el tablero conserva el centro. Las bandas laterales usan reloj arriba y fichas de jugador apiladas debajo. Cada ficha cambia a composición horizontal (avatar a la izquierda, nombre a la derecha), evitando nombres cortados o avatares aplastados. Los laterales comienzan por debajo de los controles de esquina.
- **Teléfonos estrechos**: el contenido puede compactarse, pero no se permite que el nombre quede debajo del avatar de forma accidental ni que un control se salga del viewport.

## Tipografía y nitidez
El nombre de jugador tiene prioridad sobre títulos y estados secundarios, que permanecen ocultos durante la partida. Se usan fuentes escalables, tamaños mínimos legibles y recorte controlado; no se reduce el texto a tamaños microscópicos para resolver un layout roto.

## Entrada táctil
Las acciones deben tener zonas suficientes para un dedo. Los paneles decorativos no capturan eventos. Los gestos de arrastre se distinguen de los toques y un arrastre no debe activar el control donde termina.

## Validación obligatoria antes de aceptar cambios visuales
- Capturas reales de Godot a 360×640 y 800×480.
- Comprobar el área visible de avatar, nombre, reloj, tablero, movimientos y controles.
- Probar al menos 1c1, 2c2 y contra bot.
- Revisar Output/Debugger: separar errores de GDScript de limitaciones de audio/VSync del entorno virtual.
- No llamar “validado en Android” a una prueba ejecutada solo en Xvfb.

## Restricción de arquitectura
Preferir escenas `.tscn`, contenedores, anclajes y temas del editor para estructura estática. El código de layout solo se usa para decisiones realmente dependientes de resolución/orientación, y debe consumir los tokens comunes anteriores.
