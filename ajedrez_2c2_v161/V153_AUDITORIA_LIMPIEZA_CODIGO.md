# V153 — Auditoría de limpieza de código

## Alcance de esta pasada

Se inspeccionaron los módulos globales nuevos (`core/events/`, `core/visual/`) y el mapa de sistemas, además de ejecutar el conjunto principal con Godot 4.7.2 bajo Xvfb.

## Resultado de verificación

- Suite principal: **42 OK / 0 fallaron**.
- Importación inicial del proyecto: el editor mostró incidencias de importación/cache en este entorno limpio. Por ello se repitió la suite después de la importación y el resultado funcional fue 42/0.
- Advertencias de audio/V-Sync corresponden al entorno Xvfb/Linux y no son evidencia de fallo en un dispositivo Android.

## Política de eliminación

En esta pasada no se borraron scripts de producción basándose únicamente en una búsqueda textual de referencias. En Godot, los scripts pueden enlazarse mediante `class_name`, `preload/load`, escenas, recursos, autoloads, señales o cargas dinámicas. Una búsqueda por ruta literal no demuestra que un script esté muerto.

Los archivos de `tests/` y las capturas/escenarios de QA se conservan deliberadamente: aunque algunos no estén llamados desde `tests/run_tests.gd`, pueden ser herramientas manuales o cubrir regresiones históricas. Eliminarlos sin inventario de ejecución podría reducir cobertura.

## Candidatos a revisar con más profundidad

La búsqueda estática encontró scripts que no muestran una referencia directa por ruta en escenas/recursos/scripts. Eso **no** se considera prueba suficiente para borrarlos. La siguiente fase debe crear un inventario de escenas, `preload/load`, `class_name`, autoloads, rutas construidas dinámicamente y runners de test; luego probar la eliminación de cada candidato de forma aislada y revertir si cambia el comportamiento.

## Regla de arquitectura

- Código compartido: `core/` con una única responsabilidad y contrato explícito.
- Reglas y estado de ajedrez: `domain/`.
- Composición visual: `ui/` y `scenes/`.
- Pruebas y capturas: `tests/`, fuera del código de producción.
- No introducir dependencias de UI dentro de reglas de ajedrez.

## Conclusión

Esta versión registra una auditoría conservadora y deja las pruebas verdes. **No declara finalizada la eliminación de código muerto**: todavía hace falta una pasada específica de grafo de dependencias y verificación por candidato para borrar únicamente lo confirmado como obsoleto.
