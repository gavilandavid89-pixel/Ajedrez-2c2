# V129 — Diagnóstico manual solo offline

## Decisión
El botón manual de diagnóstico QA solo aparece habilitado en el menú cuando no hay una sesión online activa. La acción vuelve a comprobar la condición al pulsarse; ocultar o deshabilitar un elemento visual no se trata como barrera suficiente.

## Cambios
- Añadida la opción `Diagnóstico QA (offline)` al menú Más del menú principal.
- Se deshabilita si la escena actual parece corresponder a online/match/matchmaking o si el servicio App expone `is_online_session_active()` o `online_session_active` y confirma una sesión activa.
- La acción comprueba otra vez la condición antes de exportar.
- Exporta un paquete QA acotado a 20 capturas recientes y muestra la ruta local `user://qa_supervisor_bundle.zip`.
- Si falla, muestra un mensaje sin exponer datos sensibles; el hub mantiene el registro del error.
- El agente de capturas rechaza de forma explícita el modo headless antes de pedir textura al renderer. Esto evita errores `Parameter "t" is null` vistos en el Output al ejecutar sin renderer gráfico.

## Validación
- Importación/editor Godot 4.7.2 repetida tras reimportar recursos: sin `SCRIPT ERROR`, `Parse Error` ni `ERROR:` en el registro final.
- Ejecución headless de 300 frames: sin errores.
- `tests/v129_offline_diagnostics_tests.gd`: 6 OK / 0 FAILED.
- La prueba headless confirma que el agente devuelve `capture_unavailable_headless` limpiamente.

## Limitaciones conocidas
- El paquete se guarda en `user://`; el diálogo enseña la ruta, pero no implementa aún el selector nativo de archivos/compartir Android.
- El guard es defensivo dentro de la app, no una frontera de seguridad de un backend. Al integrar networking real, el estado autoritativo online deberá provenir del servicio de sesión, no de la ruta de escena.
- El menú QA está en el menú principal, no dentro de una partida online. La revalidación protege también futuros cambios de navegación.
