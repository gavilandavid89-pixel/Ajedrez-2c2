# V160 — Presentación del análisis y clasificación compartida

## Cambios
- Se centralizó la paleta de categorías ya existentes en `core/review/move_classification_style.gd`.
- La nueva clase es solo de presentación: no calcula ni inventa categorías. La clasificación sigue llegando del informe existente de análisis (`moves[].classification`).
- Las jugadas de la barra consultan esa paleta solo en modo `analysis`; en `replay` vuelven a un tono neutral.
- Si una jugada no trae clasificación, conserva el color neutral de respaldo.
- El escenario de tablero ahora coloca el tablero a partir del tamaño real asignado al contenedor, centrado horizontalmente; en móvil, el coach ocupa una franja superior para no cubrir casillas. En pantallas anchas, cuando hay espacio suficiente, se coloca a la derecha sin desplazar el centro del tablero.
- Se conecta el recálculo al cambio de tamaño del área del tablero para evitar que el tablero se dibuje con medidas de un layout anterior.
- Se mantiene Nexus como dato de jugador; no se usa Elo como sustituto.

## Capturas
- `v160_analisis_centrado_coach.png`: vista vertical de análisis con datos de ejemplo.
- `v160_replay_limpio.png`: vista vertical de replay sin coach ni colores de evaluación; jugadores y relojes visibles.

## Pruebas ejecutadas
- `tests/run_tests.gd`: 42 OK / 0 fallaron.
- `tests/replay_mode_separation_tests.gd`: 9 OK / 0 fallaron.
- `tests/move_classification_style_tests.gd`: 4 OK / 0 fallaron.
- Captura real ejecutada con Godot 4.7.2 bajo Xvfb.

## Límites conocidos
- Los datos de jugadores, Nexus, tiempos y jugadas de las capturas son de prueba.
- La disposición lateral del coach en orientación horizontal está implementada en el layout responsive, pero la captura automatizada disponible en este entorno solo produjo la ventana lógica vertical; falta confirmar visualmente el caso horizontal y validar en dispositivo Android.
