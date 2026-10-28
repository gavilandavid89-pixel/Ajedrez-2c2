# TANDA 9 — Estabilidad, tacto, bots, rendimiento y distribución

## Cambios
- Entrada táctil unificada con supresión de mouse emulado durante el mismo gesto.
- El estado 2c2 mantiene separado el asiento `current_slot` del actor real `current_actor_slot()`, incluyendo cobertura de compañeros ausentes.
- Los bots usan una espera por turno con variación natural dependiente del Elo; no responden instantáneamente.
- Las sugerencias de bot usan la misma ruta de sugerencias cooperativas y no se autoaceptan.
- El HUD dejó de reconstruir tarjetas/paneles en cada ciclo: el estado importante actualiza por señal y el refresco periódico queda para relojes, cooldowns, overlays y viewport.
- Las reacciones temporales aumentaron de tamaño y pueden invadir brevemente el espacio del tablero sin cambiar el layout.
- El menú principal conserva Perfil/Rankings/Historial/Apariencia/Reacciones/Ajustes como acceso propio y usa botones más cómodos en móvil.

## Galería de Android
- Los datos de progreso se guardan en `user://ajedrez_2c2`, no en DCIM/Pictures/Movies/Download.
- Se crean `.nomedia` en la raíz de datos, caché y backup como defensa adicional frente a MediaScanner.
- Se añadió `.nomedia` también bajo `assets/` para que una copia/extracción de recursos conserve una marca de no indexación.
- No se encontraron rutas de escritura pública de galería en los scripts del proyecto.

## Verificación Godot 4.7.2
- Suite principal: 38/38 OK.
- Movimiento/bots: 20/20 OK.
- Orientación/layout: 22/22 OK.
- Touch targets: 30/30 OK.
- UI regression: 51/51 OK.
- Emote smoke: 3/3 OK.
- Tanda 9: 19/19 OK.
- Perfil/performance V27: 3/3 OK; 10 refrescos de perfil midieron ~350 ms en el entorno de prueba.
