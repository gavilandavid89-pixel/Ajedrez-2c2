# Alcance actual de interfaz

Esta versión prioriza la interfaz y la estructura visual. No se activan todavía reglas nuevas de temporadas ni se define su ciclo de vida.

## Competitivo
- Rating individual y de pareja: existentes en la base anterior.
- Copas: interfaz preparada; no se amplían aquí las reglas de cálculo.
- Rankings: interfaz para jugadores y parejas; la fuente global real llegará después con el online.
- Temporadas: solo diseño visual/preparación. No hay inicio, cierre, reinicio, ascenso, descenso ni recompensas nuevas desde esta interfaz.

## Apariencia
- Nueva sección `Apariencia` dentro de Mi cuenta.
- Identificadores persistentes separados para `board_theme` y `piece_set`.
- Conjunto actual: `classic`.
- `ChessBoardView` ya selecciona el tema de tablero y el conjunto de piezas mediante esos identificadores, aunque solo existe el conjunto clásico por ahora.
- Añadir futuros estilos no requiere rehacer el perfil ni la pantalla de ajustes; se agregan recursos y sus registros correspondientes.
