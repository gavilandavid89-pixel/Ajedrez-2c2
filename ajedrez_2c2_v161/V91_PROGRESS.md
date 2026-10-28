# V91 — PROGRESO Y CHECKPOINT

## Estado
- Reforma de Inicio completada.
- Clasificación 1c1/2c2 separada.
- QA de proyecto ejecutado.
- Captura gráfica revisada.
- Pendiente: empaquetado y verificación del ZIP exacto.

## Archivos principales modificados
- ui/screens/mode_menu.gd
- ui/screens/account_hub.gd
- ui/components/account_page_renderer.gd
- tests/home_scroll_v69_tests.gd
- tests/ranking_modes_v91_tests.gd
- tests/capture_v91_home.gd

## Reglas de QA
Siempre modificar -> ejecutar -> revisar output -> revisar debugger -> corregir -> repetir.
En cada ZIP final hay que ejecutar el ZIP exacto, no solamente la carpeta de trabajo.
