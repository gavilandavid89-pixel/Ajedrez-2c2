# Ajedrez 2c2 — V82 NEXUS-TEAM: memoria temporal de pareja

## Qué revisamos
Se realizó una revisión en dos perspectivas:

1. **Revisión principal:** buscar mejoras de precisión, estabilidad y coherencia con NEXUS V2.
2. **Revisión crítica (alter ego):** buscar sobreajuste, efectos secundarios, inconsistencias de arquitectura y datos que pudieran quedar congelados.

Ambas revisiones coincidieron en que NEXUS V2 no necesitaba otro cambio grande de fórmula.

## Mejora aplicada
El estado NEXUS-TEAM ahora trata la información de una pareja como temporal:

- `pair_uncertainty` aumenta progresivamente durante la inactividad, igual que la incertidumbre individual.
- `pair_effect` (sinergia aprendida de la pareja) pierde peso con una semivida de 45 días.
- El rating de la pareja **no baja por inactividad**.
- Al volver a jugar, `update_pair()` aplica primero el envejecimiento y después aprende con el nuevo resultado.
- Las parejas nuevas incluyen explícitamente `nexus_version = 2`.

## Por qué
Antes, una pareja podía dejar de jugar durante meses y conservar indefinidamente la misma incertidumbre y el mismo efecto de sinergia. Eso daba una falsa sensación de precisión al regresar.

La corrección mantiene el rating histórico intacto, pero hace que NEXUS vuelva a ser prudente cuando existe poca evidencia reciente.

## Revisión crítica adicional
Se detectó también `pair_stats` dentro del ciclo de partida con ajustes locales de +15/-10. Actualmente funciona como estado transitorio del tablero y no es la fuente persistente de NEXUS; el resultado competitivo persistido pasa por `PlayerData.record_result()` y NEXUS V2. No se modificó para evitar tocar comportamiento de partida sin necesidad.

También se identificó una futura mejora de integración: el resultado de partida todavía puede llegar al servicio competitivo sin un snapshot real de rating de los rivales. Eso pertenece a la capa de datos/matchmaking y no se mezcló con esta corrección matemática.

## Validación real
Godot utilizado: **4.7.2.stable.official.ed1daf0bf**.

- Import/editor headless: OK.
- NEXUS V2: **10 OK / 0 FALLARON**.
- NEXUS-TEAM: **27 OK / 0 FALLARON**.
- Matchmaking: **8 OK / 0 FALLARON**.
- Competitive: **34 OK / 0 FALLARON**.
- Account Hub: **149 OK / 0 FALLARON**.
- Profile UI: **9 OK / 0 FALLARON**.
- V56 1c1 progression: **5 OK / 0 FALLARON**.
- Match Result V71: **15 OK / 0 FALLARON**.
- Match History Integration: **5 OK / 0 FALLARON**.
- History Interface V35: **20 OK / 0 FALLARON**.
- History Profile V73: **5 OK / 0 FALLARON**.
- 1c1 online shell: **3 OK / 0 FALLARON**.
- Smoke real de Godot 4.7.2 a 720×720: sin `SCRIPT ERROR` ni `Parse Error`; solo advertencias de V-Sync/audio propias del entorno de ejecución.

## Reglas 2c2
No se modificaron las reglas, turnos, Sugerir, Cambio ni lógica de juego.
