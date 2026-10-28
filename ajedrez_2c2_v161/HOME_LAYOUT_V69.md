# Ajedrez 2c2 — Home V69

## Objetivo
Reorganizar la pantalla principal como una página móvil vertical con scroll real. El contenido no intenta caber entero en el viewport.

## Jerarquía
1. Perfil arriba izquierda.
2. Ajustes arriba derecha.
3. Título.
4. `JUGAR` como acción principal.
5. `JUGAR` abre un menú compacto con `1c1`, `2c2` y `LOCAL`.
6. `JUGAR CONTRA BOTS` lleva a su pantalla independiente.
7. `ÚLTIMAS PARTIDAS` es una sección de contenido, no un botón gigante.
   - Partida no analizada: `ANALIZAR`.
   - Partida analizada: `VER`.
   - Siempre existe `Ver todo el historial`.
8. `TEMPORADA ACTUAL` aparece más abajo y se descubre mediante scroll.
9. Navegación inferior reservada para `Inicio`, `Club`, `Amigos` y `Más`.

## Principios respetados
- Mobile-first.
- Scroll vertical natural.
- Nada importante se comprime para caber en un único viewport.
- La pantalla principal no intenta mostrar todas las funciones del juego.
- Las opciones secundarias quedan fuera del foco principal.
- El menú de Jugar reutiliza el patrón de menú compacto usado en otras partes del juego.
- No se modificaron reglas 1c1/2c2 ni lógica competitiva.
- Se conservan nodos de compatibilidad para tests y flujos existentes.

## Verificación Godot 4.7.2
- Core: 39/39
- Home Scroll V69: 17/17
- Navegación: 18/18
- Online setup: 37/37
- Responsive mode menu: 37/37
- Account Hub: 149/149
- V28 refinement: 23/23
- Module contracts: 17/17
- Chess domain contracts: 10/10
- Bot integration: 6/6
- Bot difficulty: 39/39
- Modular architecture runner: 44/44
- Editor/import: OK

Los warnings de root/audio y recursos liberados al terminar algunos runners pertenecen al entorno headless de prueba; no hubo errores de parser ni fallos funcionales en las suites indicadas.
