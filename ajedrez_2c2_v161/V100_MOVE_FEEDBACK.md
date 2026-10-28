# V100 — Movimiento visible, últimas casillas y golpe de madera

## Cambios
- Movimiento de piezas con interpolación cúbica y duración más visible (aprox. 0,28–0,45 s según distancia), con elevación visual ligera.
- Resaltado amarillo translúcido de origen y destino, persistente tras aterrizar y compatible con orientación Blancas/Negras.
- El resaltado se limpia al reiniciar o comenzar una revancha.
- El sonido de aterrizaje usa un ataque corto de ruido y resonancias no armónicas graves para aproximar el golpe de una pieza sobre madera. Las capturas usan un golpe un poco más grave y fuerte.
- Se mantiene el motor lógico autoritativo: las animaciones son una capa visual y no alteran legalidad, capturas ni turno.
- El enroque mantiene sus dos segmentos animados; el sonido se reproduce al finalizar el movimiento visual.

## Validación en Godot 4.7.2
- `move_feedback_v100_tests.gd`: 14/14
- `piece_move_animation_v92_tests.gd`: 13/13
- `skin_independent_preview_v98_tests.gd`: 13/13
- `skin_ui_interaction_v98_tests.gd`: 10/10
- `skin_graphite_gold_v97_tests.gd`: 36/36
- `run_tests.gd`: 39/39
- `personalization_tests.gd`: 14/14
- `account_hub_tests.gd`: 149/149 (con directorio de datos de prueba limpio)
- `full_screen_flow_audit_v87.gd`: 18/18; 246 interacciones

## Inspección visual
Captura de partida real renderizada por Godot 4.7.2 con OpenGL/llvmpipe. Se verificó un fotograma intermedio con la pieza entre origen y destino, y otro al terminar; ambas casillas quedan resaltadas. El entorno de captura no dispone de dispositivo ALSA, por lo que Godot cae al driver de audio dummy durante QA; esto es una limitación del contenedor, no un error GDScript. El audio en ejecución normal usa el sistema de audio de Godot.
