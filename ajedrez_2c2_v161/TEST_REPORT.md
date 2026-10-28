# Informe de pruebas — Ajedrez 2c2

Fecha de esta iteración: 2026-09-29
Motor: Godot 4.7.2.stable
Viewport base: 720x1280

## Lógica

**37 OK / 0 fallaron.**

Incluye tablero 8x8, movimientos, capturas, turnos A-B-C-D, sugerencias, cuestionar, cambios gratuitos sin monedas, rendición, tablas, ausencia/regreso, reloj por equipo, estadísticas, jaque, mate, ahogado, enroque, en passant, promoción, historial y emotes.

## Perfiles

**9 OK / 0 fallaron.**

- Cuatro perfiles 2c2.
- Reemplazo dinámico por slot.
- VS IA sin herramientas cooperativas.
- Perfil de IA.
- Perfiles de 1c1 local.
- Cooldown de sugerencia: 2 s.
- Cooldown de cuestionar: 2 s.

## Regresión UI clásica

**33 OK / 0 fallaron.**

Comprueba modos, tablero responsive, giro de 1c1 local y visibilidad de herramientas por modo.

## Auditoría visual responsive

**1534 OK / 0 fallaron.**

Viewports: 360×640, 390×844, 412×915, 720×1280, 800×480, 1024×600, 1280×720 y 1920×1080, recorriendo 2c2, 1c1, VS IA y 1c1 local.

La auditoría comprueba además:
- no solapamiento de tarjetas;
- nombres de jugador que caben en sus labels;
- un solo reloj por equipo/lado;
- título de modo sin colisión con botones superiores;
- controles inferiores dentro de su panel y sin solaparse;
- menús contextuales dentro del viewport;
- menú de modos sin botones superpuestos;
- entrada real del tablero `e2 → e4` usando la geometría responsive.

## Correcciones de esta iteración

- Los controles auxiliares compactos de la barra inferior pasan a 32 px de alto para no desbordar la fila.
- El layout compacto mantiene dos filas cuando el ancho no permite una sola.
- La barra superior usa iconos compactos en tamaños estrechos.
- Se reforzaron las restricciones de tarjetas para evitar solapamientos y truncamientos futuros.
- Se verificó que las tarjetas no contienen relojes individuales.
- Los relojes siguen siendo uno por equipo/lado.
- El intercambio 2c2 es gratuito y no usa monedas.

## Capturas

La iteración final se probó visualmente con render OpenGL bajo Xvfb.

Los avisos ALSA pertenecen al entorno de prueba sin dispositivo de audio y no son fallos del proyecto.

## Revisión 1c1 Online — 2026-09-29
- 37 pruebas base: 37 OK / 0 fallos.
- 9 pruebas extra: 9 OK / 0 fallos.
- 9 pruebas de perfiles/UI: 9 OK / 0 fallos.
- 44 regresiones de UI: 44 OK / 0 fallos.
- 1502 checks responsive: 1502 OK / 0 fallos.
- 2 pruebas de carcasa de matchmaking: 2 OK / 0 fallos.

Controles online durante la partida: sin Menú/Reiniciar; salida disponible al finalizar por resultado, rendición o tablas.

## Última iteración: online setup

- Mini menú modal al elegir 2c2 o 1c1 online.
- Selección 10'/15'/20'.
- Sala privada con QR, enlace, código y botones de regeneración/copiar.
- Pantalla de matchmaking pública/espera privada.
- Pruebas de flujo, geometría y reloj: 22/22 OK.
- Revisión anterior de base lógica: 37/37 OK.
- Regresión UI: 44/44 OK.
- Auditoría visual responsive: 1502/1502 OK.
- Perfil/UI: 9/9 OK.

La red real aún no está conectada.

## Corrección de unión a sala — 2026-09-29
- Se añadió `Unirse a una sala` a la pantalla de amigo.
- Se validan códigos de 6 caracteres y enlaces de invitación.
- El flujo distingue `friend` (crear) de `friend_join` (unirse).
- 1c1 y 2c2 conservan correctamente el papel del invitado.
- El tiempo de la partida al unirse se considera propiedad de la sala del anfitrión.
- `tests/online_setup_tests.gd`: 29/29 OK.
- `tests/run_tests.gd`: 37/37 OK.
- Ejecución principal headless: código 0, sin errores de script ni parse errors.

## Actualización de revisión de base

- Perfil/cuenta local añadido.
- Ranking individual y de parejas añadido como estructura local de UX.
- Pantalla de copas añadida sin fijar todavía una fórmula de ganancia/pérdida.
- Ajustes persistentes añadidos y conectados al tablero/flujo de rendición.
- Auditoría responsive extendida a la pantalla de cuenta.
- `account_hub_tests.gd`: 44/44 OK.
- `ui_visual_regression.gd`: 1514/1514 OK.

La capa de red real sigue fuera de esta etapa.


## Sistema competitivo — 2026-09-30

- `tests/competitive_system_tests.gd`: **24/24 OK**.
- `tests/matchmaking_logic_tests.gd`: **8/8 OK**.
- `tests/account_hub_tests.gd`: **44/44 OK**.
- `tests/run_tests.gd`: **37/37 OK**.
- `tests/online_matchmaking_test.gd`: **3/3 OK**.
- `tests/online_setup_tests.gd`: **29/29 OK**.
- `tests/ui_regression.gd`: **44/44 OK**.
- `tests/ui_visual_regression.gd`: **1514/1514 OK**.

La pantalla de cuenta se revisó con render OpenGL en 360×640, además de las pruebas estructurales en 390×844, 720×1280 y 1280×720. Se corrigió un solapamiento real producido por tarjetas con múltiples hijos directos y se pasó la navegación de cuenta a una cuadrícula responsive de pestañas.

`PlayerData` quedó como autoload para que rating, copas, estadísticas y ajustes estén disponibles desde el inicio del juego, sin depender de visitar la pantalla de cuenta.

La red/servidor real sigue fuera de esta etapa.
