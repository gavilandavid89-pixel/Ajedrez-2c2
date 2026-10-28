# v28 — Refinamiento de UX, bots y rendimiento

## Cambios
- Perfil convertido en pantalla informativa única; se eliminó la navegación secundaria del propio perfil.
- Ranking individual/parejas, historial, apariencia, reacciones y ajustes pasan a accesos del menú principal.
- Menú principal usa una rejilla de accesos compactos, sin apariencia de barra web.
- Ranking conserva tablas individuales y de parejas fuera del perfil.
- Bots tienen tiempo de pensamiento progresivo por dificultad: nunca juegan instantáneamente.
- Bots 2c2 pueden generar una sugerencia visible para el compañero humano sin mover la pieza por aceptarla.
- Entrada de tablero mantiene toque directo y añade arrastre pieza→destino en un solo gesto.
- Reacciones mostradas en partida aumentan de tamaño y pueden sobresalir temporalmente de la tarjeta.
- Caché de texturas de reacciones para evitar cargas repetidas.
- Selector de reacciones ya no ejecuta trabajo cada frame.

## Pruebas Godot 4.7.2
- Core: 38/38
- Account Hub: 96/96
- UI regression: 51/51
- Responsive touch targets: 30/30
- Tandas 5–7: 23/23
- Tanda 8: 5350/5350
- Runtime service safety: 4/4
- Profile performance: 3/3
- Refinamiento v28: 22/22

Las suites de estrés pueden mostrar advertencias de liberación de objetos al salir del arnés de pruebas; las comprobaciones terminan con código 0.
