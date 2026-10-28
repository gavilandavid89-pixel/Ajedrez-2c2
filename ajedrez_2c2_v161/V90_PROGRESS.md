# V90 — reforma de Inicio móvil

## Objetivo
Reorganizar Inicio para que la primera acción sea claramente de juego móvil y mover “Más opciones” a un menú de tres puntos arriba a la derecha.

## Cambios
- Encabezado con más aire y avatar predeterminado reducido para no invadir el contenido.
- `JUGAR` queda inmediatamente debajo del encabezado.
- `JUGAR CONTRA BOTS` queda inmediatamente después de `JUGAR`.
- Se eliminó la sección textual “MÁS OPCIONES” del contenido.
- Se añadió `MoreButton` (`⋮`) arriba a la derecha.
- `MoreMenu` contiene Club, Amigos, Ajustes, Rankings y Perfil.
- Historial compactado y con acciones más contenidas.
- Separadores horizontales sustituidos por espaciado vertical de sección.
- Temporada conserva progreso y ahora “Ver temporada” es accionable.
- Navegación inferior se mantiene: Inicio, Club, Amigos, Más.

## QA ejecutado
- Importación/editor: RC 0.
- Home Scroll V69: **25/25 OK**.
- Runner general: **39/39 OK**.
- Flujo completo: **18/18 OK, 252 interacciones**.
- Captura gráfica 720×1280: OK.
- Output de proyecto: sin `SCRIPT ERROR`, `Parse Error`, `Failed loading resource`, leaks, `ObjectDB` ni `Orphan` en los runners de prueba.

## Mensajes de entorno gráfico
- V-Sync no disponible en driver virtual.
- ALSA/PulseAudio no tiene dispositivo; Godot usa driver de audio dummy.
- `ERR_CANT_OPEN` asociado únicamente a inicialización del dispositivo de audio del entorno QA.
