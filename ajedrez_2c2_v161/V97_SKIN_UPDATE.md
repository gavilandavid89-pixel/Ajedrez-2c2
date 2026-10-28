# V97 — Actualización de skin Grafito + dorado

## Objetivo
Corregir únicamente la skin opcional `graphite_gold` según la última especificación visual.

## Regla de aislamiento
- `classic` sigue siendo la skin predeterminada.
- Los 12 assets de `assets/pieces/` no se modificaron.
- La skin nueva mantiene sus assets independientes en `assets/pieces/skin_graphite_gold/`.
- Crear/modificar una skin no modifica ninguna otra skin.

## Cambios visuales
### Blancas — Grafito + dorado
- Relleno interior completamente blanco.
- Contorno y detalles amarillo/dorado.
- El relleno no sustituye ni modifica las piezas clásicas.

### Negras — Grafito + dorado
- Relleno negro.
- Se conserva el contorno/acento azul acero de la skin.
- Se elimina visualmente la identidad de contorno gris de esta skin.

### Tablero
- Se mantiene el tablero propio de `graphite_gold`.
- No se modifica el tablero clásico.

## QA ejecutado
- `skin_graphite_gold_v97_tests.gd`: 36/36.
- `filled_piece_skin_v96_tests.gd`: 24/24.
- `default_skin_v93_tests.gd`: 37/37.
- `tanda_9_stability_tests.gd`: 19/19. Se corrigió un falso fallo del test que comparaba `experto`, un ID que no existe en el roster actual, contra `mateo`; se sustituyó por `aegis`, el bot real de 1800 Elo.
- `run_tests.gd`: 39/39.
- Parse contracts V85: 10/10.
- Ejecución GUI real con Godot 4.7.2 + Xvfb/llvmpipe: salida sin `SCRIPT ERROR`, `Parse Error` ni `Failed loading resource`.
- Los únicos mensajes del entorno GUI son V-Sync no soportado y ausencia de dispositivo ALSA, con fallback a audio dummy.
- Captura visual real inspeccionada: `V97_GRAPHITE_GOLD_BOARD.png`.
- Captura de Experiencia inspeccionada: `V97_GRAPHITE_GOLD_ACCOUNT.png`.
- Comparación SHA-256 de los 12 PNG clásicos antes/después: idéntica.
