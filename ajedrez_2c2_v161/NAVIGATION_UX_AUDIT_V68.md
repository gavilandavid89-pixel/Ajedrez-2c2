# Auditoría de navegación y organización — V68

## Hallazgos corregidos

1. **Perfil**: se eliminó la barra de navegación global del perfil. Perfil queda como pantalla de información propia.
2. **Accesos contextuales**: Perfil ahora tiene iconos visibles para **Historial** y **Ajustes**, con tooltips claros.
3. **Personalización**: la opción antes llamada **Reacciones** ahora se presenta como **Experiencia**, porque contiene tablero, piezas y reacciones.
4. **1c1 Local**: dejó de saltar directamente a la partida y ahora tiene su propia pantalla de preparación, con selección de tiempo y botón de inicio.
5. **Menú principal**: se añadieron separadores visibles **JUGAR ONLINE** y **JUGAR SIN ONLINE** para que los grupos de modos no parezcan una lista plana.

## Jerarquía revisada

- Menú principal → selección de modo.
- 2c2 / 1c1 online → preparación online.
- VS IA → selección de bot.
- 1c1 Local → preparación local.
- Perfil → información + accesos contextuales.
- Rankings → rankings/copas/temporadas preparadas.
- Historial → partidas → análisis/replay.
- Más → ayuda y funciones secundarias.
- Experiencia → tablero/piezas/reacciones.
- Ajustes → preferencias generales.

## Verificación

- Godot 4.7.2: importación limpia.
- Navegación V31: 18/18.
- Personalización: 14/14.
- Account Hub: 149/149.
- Core: 39/39.
- Regresión UI V60/V61 y menú responsive: sin regresiones observadas.

No se modificaron reglas de ajedrez ni mecánicas 2c2.
