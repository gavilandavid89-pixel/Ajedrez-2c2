# V56 — QA final

## Objetivo
Refinar el competitivo 1c1 sin modificar las mecánicas del 2c2.

## Cambios validados
- Corregido `rating_after`/`cups_after` del historial para que en 1c1 apunten al bloque `individual_1c1`.
- Racha de victorias 1c1 independiente.
- Resultado 1c1 muestra cambio + total de rating/copas + liga + racha.
- Menú 1c1 muestra rating, liga, copas, racha y distancia a la siguiente liga.
- Tarjeta de rival 1c1 evita duplicar el texto `Rival` como nombre y título.
- No se cambió ninguna mecánica del 2c2 ni Sugerir.

## Pruebas Godot 4.7.2
- V56 específica 1c1: **5/5**
- Competitivo: **34/34**
- UI regression: **53/53**
- Mode Menu responsive: **27/27**
- Core runner: **39/39**
- Importación limpia de assets con `--import`: **OK**
- Captura visual 1c1 360x640: **revisada**

## Observaciones del entorno
- Audio cae a driver dummy porque el entorno de laboratorio no expone un dispositivo ALSA.
- El renderer visual de QA usa llvmpipe mediante Xvfb/GL compatibility.
- La suite UI todavía reporta 2 `ObjectDB` leaks al salir del arnés; las aserciones son 53/53 y el problema pertenece al cierre del runner de pruebas, no a una aserción funcional fallida.
