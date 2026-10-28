# V95 — Skin opcional sin reemplazar el estilo clásico

Se conserva el tablero y piezas originales como `classic`. **Classic sigue siendo el estilo seleccionado por defecto**.

Se agrega `graphite_gold` como una skin independiente y seleccionable desde Experiencia de juego:
- Tablero grafito + gris metal con marco dorado.
- Piezas blancas con silueta completamente rellena en blanco y detalles dorados.
- Piezas negras completamente negras con contorno azul acero oscuro, elegido para armonizar con el negro en lugar del gris anterior.
- Assets aislados en `assets/pieces/skin_graphite_gold/`.
- La selección completa sincroniza tablero y piezas sin alterar la apariencia clásica.

La pantalla de Experiencia de juego ofrece una selección de skin completa y mantiene controles independientes para tablero y piezas.

## QA real V95

Ejecutado con **Godot 4.7.2 real**, con inspección de salida y debugger.

En el directorio de trabajo:
- Skin clásica + opcional: **37/37 OK**
- Animación de movimiento: **13/13 OK**
- Personalización: **14/14 OK**
- Account Hub: **149/149 OK**
- Auditoría de flujo de pantallas: **18/18 OK — 255 interacciones**
- Suite general: **39/39 OK**
- No se detectaron `SCRIPT ERROR`, `Parse Error`, `Failed loading resource`, `Leaked instance` ni `Orphan` en las ejecuciones verificadas.

Validación del **ZIP exacto** después de empaquetarlo:
- `unzip -t`: **sin errores**.
- Skin clásica + opcional: **37/37 OK**.
- Animación de movimiento: **13/13 OK**.
- Account Hub: **149/149 OK**.
- Suite general: **39/39 OK**.
- Ejecución gráfica real desde el ZIP exacto: **RC 0** y captura de clásico + grafito/dorado + pantalla de experiencia.
- Scan del debugger de la ejecución gráfica: **limpio**.

Las únicas advertencias de la ejecución gráfica provienen del entorno (V-Sync no disponible y dispositivo ALSA físico ausente, con fallback a audio dummy), no del proyecto.
