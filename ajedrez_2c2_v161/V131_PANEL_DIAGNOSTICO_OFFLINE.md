# V131 — Panel de diagnóstico offline

## Cambios
- El elemento `Diagnóstico QA (offline)` abre ahora un panel legible con hasta 20 eventos recientes, su severidad, agente, código y detalles.
- Desde ese panel se puede solicitar la exportación del paquete QA.
- La restricción offline se comprueba al abrir el panel y se vuelve a comprobar justo antes de exportar.
- El texto del panel advierte que los detalles pueden contener rutas locales y que deben revisarse antes de compartir.
- El botón sigue siendo parte del menú de opciones y se deshabilita cuando la política detecta una sesión online/matchmaking.

## Pruebas
- V131 panel: 6/6.
- V130 rotación/paquete QA: 4/4.
- V129 restricción offline: 6/6.
- V128 recuperación de diario: 8/8.
- V127 integración de supervisión: 15/15.
- V126 capturas: 8/8.
- V125 tablero/piezas: 7/7.
- V124 miniagentes: 12/12.
- V123 supervisor de partidas: 22/22.
- Importación del proyecto Godot 4.7.2: código de salida 0; sin `SCRIPT ERROR`, `Parse Error` ni `ERROR:` en el registro revisado.

## Limitaciones conocidas
- La inspección de la interfaz se ha validado por pruebas de contrato y lógica, no por un recorrido visual manual completo en dispositivo Android.
- El botón muestra y exporta datos locales; no inicia un envío de red. La política online actual depende de la detección interna de escena/estado de sesión y deberá conectarse al estado autoritativo cuando exista backend real.
- La exportación ZIP se mantiene en `user://`; todavía no se implementó el selector/compartir nativo Android.
