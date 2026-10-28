# V54 — Bucle competitivo y postpartida

## Objetivo

Hacer que una partida 2c2 tenga una continuidad clara: **jugar → resultado → progreso → análisis → siguiente partida**.

## Cambios

- La pantalla de resultado ahora muestra el cambio competitivo inmediato de la partida:
  - Rating ganado/perdido.
  - Copas ganadas/perdidas.
- Se añadió `Analizar` directamente al resultado.
- `Analizar` abre el estudio de la última partida guardada sin obligar a pasar primero por Historial.
- El estudio selecciona automáticamente la partida más reciente cuando se abre sin un registro explícito.
- La pantalla principal muestra bajo 2c2 el rating individual, liga y copas actuales.
- Ese indicador se actualiza cuando cambia el progreso local.
- No se presenta el ranking local como ranking global: seguirá marcado como local hasta que exista servidor/persistencia autoritativa.

## Mecánicas protegidas

- No se cambiaron turnos, equipos, colores ni condiciones de victoria/derrota.
- `Sugerir` continúa siendo una propuesta visual origen → destino; nunca mueve la pieza.
- No se modificaron las reglas del 2c2.

## QA

- Godot 4.7.2: proyecto importa y registra las clases correctamente.
- Core: 39/39.
- UI regression: 53/53.
- Responsive visual: 1464/1464.
- Sugerencias V50: 19/19.
- Tanda 8: 5356/5356.
- Account Hub: batería ejecutada sobre 360×640, 390×844, 720×1280 y 1280×720 sin regresiones reportadas.
- Captura visual de resultado móvil revisada en 360×640.
