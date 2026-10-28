# V53 — Responsive horizontal/vertical + QA de flujo

Fecha: 2026-10-04  
Motor: Godot 4.7.2.stable

## Cambios reales

### 1. Horizontal
- Se amplió la reserva inferior del layout horizontal para que el bloque de acciones no pueda quedar fuera del viewport en 800×480, 1024×600, 1280×720 y 1920×1080.
- La fila de jugadores de los paneles laterales de 2c2 queda separada del título/reloj.
- En columnas laterales estrechas los títulos se compactan a `NEGRAS`/`BLANCAS` para evitar que invadan el reloj.

### 2. Vertical móvil
- Se reajustó el espacio reservado del tablero en teléfonos cortos para mantener controles inferiores completamente dentro de la pantalla.
- El indicador de turno queda dentro del hueco entre el equipo superior y el tablero.
- La barra inferior compacta conserva dos filas y objetivos táctiles útiles sin desbordar 360×640.
- Los títulos superiores compactos usan nombres cortos (`2c2 · COOP.`, `1c1 · ONLINE`, `VS IA`, `1c1 · LOCAL`) cuando el ancho lo exige.

### 3. Tarjetas de jugador
- El nombre visible mantiene un tamaño estable en tarjetas móviles para evitar desbordes de texto.
- Se conserva el límite de 10 caracteres definido para nombres visibles.
- No se elimina información de jugador ni el sistema de roles/estado.

### 4. Historial y Sugerir
- Se corrigieron tests que todavía esperaban el flujo anterior de Historial.
- Historial sigue entrando directamente al estudio guardado, sin pantalla intermedia redundante.
- Sugerir sigue siendo exclusivamente una propuesta: entrar en modo Sugerir no crea una jugada y solo se genera la propuesta después de origen + destino.

## Validación

- Godot 4.7.2: apertura del editor sin errores de parseo.
- Núcleo: 39/39.
- Account Hub: 140/140.
- Bots: 39/39.
- Integración bots: 6/6.
- Competitivo: 24/24.
- Historial: 20/20.
- Matchmaking: 8/8.
- Movimiento/bots: 22/22.
- Navegación: 17/17.
- Base extra: 9/9.
- Online setup: 37/37.
- Personalización: 14/14.
- Perfil/UI: 9/9.
- Refinamiento: 6/6.
- Runtime safety: 4/4.
- Storage: 18/18.
- Tanda 8: 5353/5353.
- Tanda 9: 19/19.
- Tandas 5–7: 23/23.
- UI regression: 51/51.
- Auditoría visual responsive: **1464/1464**.
- V49 Sugerir/bot: 8/8.
- Replay móvil: 10/10.
- V50 Sugerencias: 19/19.
- Capturas gráficas reales revisadas en 360×640 y 390×844 mediante Godot + Xvfb/llvmpipe.

Las advertencias `ObjectDB leaked` y los mensajes ALSA observados pertenecen al arnés/entorno de pruebas; no provocaron fallos de las aserciones. El audio cae al driver dummy cuando el entorno no tiene dispositivo de sonido.

## Restricciones preservadas

- No se cambiaron turnos, equipos, colores ni legalidad del 2c2.
- No se cambió la mecánica de Sugerir.
- No se activó una lógica nueva de temporadas.
- No se convirtió el online temporal en red real.
