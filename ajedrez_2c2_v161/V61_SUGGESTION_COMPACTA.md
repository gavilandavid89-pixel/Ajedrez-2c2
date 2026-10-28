# V61 — Sugerencia compacta y no intrusiva

## Objetivo
Reducir la superficie visual de la sugerencia del compañero sin cambiar la mecánica 2c2 ni Sugerir.

## Cambios
- El panel de sugerencia ya no se superpone al tablero en vertical ni en horizontal.
- En vertical se inserta en el espacio sobrante inmediatamente debajo del tablero.
- En horizontal ocupa la columna lateral debajo del jugador.
- Se eliminó del panel el cooldown visible.
- Se eliminó el texto de revisión/decisión.
- El encabezado ahora usa el nombre real del compañero entre comillas y respeta el límite de 10 caracteres.
- El cuerpo queda como: `sugiere e5` (destino real de la sugerencia).
- Acciones visuales: `✅`, `❌`, `❔❔`.
- `❔❔` mantiene la misma acción `challenge`; no cambia su lógica.
- El nombre del compañero es el área de arrastre del panel.
- El panel puede moverse dentro del viewport sin salirse.
- Al cerrar/usar la sugerencia se restablece el modo contextual.
- El chat sigue siendo un panel separado; en horizontal queda debajo del jugador y se abre/cierra desde su propio icono.

## Integridad de mecánicas
No se cambiaron:
- reglas del ajedrez;
- turnos 2c2;
- equipos o colores;
- aceptación/rechazo de Sugerir;
- cuestionar como acción del compañero;
- condiciones de victoria/derrota;
- cooldowns internos de Sugerir/Cuestionar.

Solo se eliminó su representación visual dentro de la tarjeta.

## Validación Godot 4.7.2
- Core: 39/39
- UI regression: 53/53
- Movimiento/Bots: 21/21
- Competitivo: 34/34
- Flujo Sugerir: 19/19
- Orientation/Chat/Action Menu: 15/15
- Responsive touch: 30/30
- Nueva suite V61: 22/22
- Editor/importación: correcta, sin errores de parseo

Las advertencias `ObjectDB leaked` del arnés de pruebas siguen siendo las mismas advertencias de cierre observadas en las suites anteriores; ninguna aserción funcional falló.
