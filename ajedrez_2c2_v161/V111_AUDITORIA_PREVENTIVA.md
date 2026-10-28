# Ajedrez 2c2 — V111 Auditoría preventiva de lógica y mantenibilidad

## Alcance

Se revisaron especialmente el adaptador UCI de Stockfish, la entrada del revisor de partidas, el núcleo NEXUS y los tests de regresión. No se modificó la rotación ni ninguna regla propia de 2c2.

## Cambios seguros aplicados

1. **Menor presión de memoria al preparar Stockfish.** `is_available()` ya no carga el binario completo solo para conocer su tamaño. `ensure_runtime_binary()` copia el ejecutable por bloques de 1 MiB, verifica el tamaño final y comprueba el resultado de `chmod`. Esto evita reservar decenas de megabytes de RAM de golpe y detecta copias incompletas.
2. **Validación de entradas antes de arrancar el motor.** Se valida la estructura básica de los seis campos FEN, sus ocho rangos, el número de reyes, derechos de enroque, casilla al paso y contadores. Las jugadas se limitan a coordenadas UCI y sufijo de promoción válidos. Se rechazan saltos de línea y órdenes adicionales, evitando entradas corruptas/inyección de comandos UCI y esperas largas por un replay defectuoso.
3. **Evaluación de mates con distancia.** Antes, `score mate 1` y `score mate 5` se reducían al mismo valor, ocultando la diferencia entre mate más rápido y mate más lento. Ahora se conserva la distancia con una escala compatible con la clasificación basada en centipeones.
4. **Límites defensivos.** La profundidad de análisis queda acotada a 1–30 y MultiPV a 1–5, evitando configuraciones accidentales excesivas.
5. **Pruebas añadidas.** Se comprueba que se rechace un FEN sin reyes y una jugada con texto añadido, y que el mate cercano puntúe mejor que el lejano tanto al atacar como al defenderse.

## Pruebas ejecutadas con Godot 4.7.2

- Pruebas generales: **41/41**.
- NEXUS V2: **10/10**.
- NEXUS-TEAM: **27/27**.
- Orientación y distribución: **42/42**.
- Auditoría de flujos de pantalla: **18/18**, 252 interacciones recorridas.

Las pruebas UCI usan un motor simulado. No equivalen a ejecutar el binario Stockfish Android ARM64 en un teléfono real.

## Riesgos detectados que no se alteraron en esta ronda

- **Análisis sincrónico:** revisar una partida larga realiza varias búsquedas por jugada y puede bloquear la interfaz mientras el motor trabaja. La solución correcta es aislar el trabajo en un hilo/servicio cancelable, con progreso y entrega segura de resultados; es un cambio arquitectónico separado que necesita pruebas de ciclo de vida.
- **Tablas reglamentarias:** la lógica de partida/replay no modela de forma completa la repetición triple ni el contador de 50 movimientos; el FEN del revisor usa contador de medio movimiento `0`. Debe abordarse como un cambio explícito de reglas y persistencia, no mezclarse con esta reparación preventiva.
- **FEN no equivale a posición legal:** la validación añadida comprueba sintaxis y estructura básica, no demuestra que una posición sea legal según todas las reglas de ajedrez. Stockfish sigue siendo quien interpreta la posición.
- **Validación en dispositivo:** el ejecutable incluido es ELF AArch64 para Android. Falta probar arranque, permisos, consumo de memoria, timeout y cierre en un dispositivo Android real.
- **Persistencia competitiva:** la protección local contra resultados inválidos es útil, pero la idempotencia frente a retransmisiones/doble confirmación requiere una autoridad de partida y un identificador de resultado persistente. No se cambió el formato de resultados ni las reglas 2c2.

## Criterio de mantenimiento

Los cambios nuevos están concentrados en `domain/bots/stockfish_engine.gd` y sus pruebas UCI. No se reescribieron sistemas ni se cambiaron ratings, turnos, cooperación o reglas de 2c2. Cada mejora queda cubierta por una prueba de regresión enfocada.
