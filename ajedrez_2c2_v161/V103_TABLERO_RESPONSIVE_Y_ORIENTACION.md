# V103 — Tablero responsive y orientación móvil

## Objetivo
Resolver el desequilibrio vertical de V102 y comprobar el diseño en orientación vertical y horizontal con Godot 4.7.2.

## Cambios
- `core/layout/layout_metrics.gd`: el bloque vertical completo (jugador superior, tablero, línea de movimientos, jugador inferior y controles) se centra como una sola composición. El tablero conserva forma cuadrada, centrado horizontal y márgenes simétricos.
- `ui/components/game/game_hud_layout.gd`: el panel del equipo superior se mueve junto al tablero en vertical; ya no queda pegado al borde mientras el tablero aparece muy abajo.
- `core/layout/layout_metrics.gd`: en horizontal se reserva más espacio inferior y se separa la barra de acciones de la etiqueta de movimientos para que no se superpongan.
- `project.godot`: orientación de dispositivo configurada como sensor (`display/window/handheld/orientation = 6`) para admitir cambios entre vertical y horizontal en Android.
- `tests/v103_responsive_orientation_tests.gd`: pruebas de configuración de orientación, límites del tablero, separación de la barra y paneles laterales en horizontal.

## Validación ejecutada en Godot 4.7.2
- `tests/run_tests.gd`: **39/39**.
- `tests/orientation_layout_v22.gd`: **22/22**.
- `tests/v102_board_centering_tests.gd` (ahora prueba el bloque completo): **54/54**.
- `tests/v103_responsive_orientation_tests.gd`: **42/42**.
- Ejecuté la escena real `res://scenes/game.tscn` en ventana vertical de 412×915 y horizontal de 915×412. Las grabaciones MP4 corresponden a la partida en ejecución, no al editor de Godot.

## Limitaciones
La comprobación de giro se hizo verificando la configuración de orientación y ejecutando la misma escena en ambas proporciones. No equivale a probar el giro físico en un teléfono Android real; eso debe confirmarse al instalar/exportar la aplicación en el dispositivo.
