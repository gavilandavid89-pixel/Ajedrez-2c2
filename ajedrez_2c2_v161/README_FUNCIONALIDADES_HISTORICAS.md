# Ajedrez 2c2 — base modular

Proyecto Godot 4.7.2 con tablero, reglas de ajedrez, modos y HUD modular.

## Modos

- 2c2 cooperativo: A → B → C → D, perfiles por slot, sugerencias, cuestionar, cambios, chat, tablas, rendición y ausencia.
- 1c1 clásico: solo reglas normales de ajedrez.
- VS IA: solo reglas normales + IA local; no muestra herramientas de equipo.
- 1c1 local: clásico para dos personas en el mismo dispositivo, con rotación del tablero después de cada jugada.

## Interfaz

La UI se construye con escenas y controles de Godot, no como una sola imagen.

- `scenes/player_card.tscn`: tarjeta reutilizable de jugador.
- `profile_data.gd`: catálogo de perfiles de demostración.
- `assets/avatars/*.svg`: avatares intercambiables.
- `scenes/game_hud.tscn`: HUD del juego.
- `scenes/game_hud.gd`: distribuye la UI según el modo y el estado de la partida.

Los paneles de jugador cargan avatar, nombre, rol y estado desde datos; el reloj es único por equipo y vive en la cabecera del equipo. En una integración online, se puede reemplazar el perfil de cualquier slot con:

```gdscript
state.set_slot_profile(slot, profile_id, display_name)
```

Sin tocar la escena de la interfaz.

## Estilo visual

Paleta cálida de carbón, madera, crema y dorado. Los paneles secundarios (sugerencias, cambio, rendición, tablas, historial y chat) aparecen como mini-paneles contextuales para no cubrir el tablero entero.

## Cooldowns

- Sugerir: 2 s.
- Cuestionar: 2 s.

## Tablero

El tablero se calcula al tamaño del viewport y se centra en X. En vertical ocupa todo el ancho disponible de la pantalla, manteniendo la distribución del HUD.


## Actualización de piezas
Las piezas usan sprites PNG recortados, centrados y escalados al 90% de la casilla para conservar buena presencia visual sin desbordarse. El intercambio de posición 2c2 es gratuito.

## V53 — Responsive horizontal/vertical

- Layout horizontal con reserva inferior corregida para evitar desbordes en pantallas anchas y bajas.
- Layout vertical corto ajustado para que tablero, equipos, estado y controles quepan en 360×640.
- Títulos compactos y nombres de jugador protegidos contra desbordes.
- Auditoría responsive: 1464/1464 OK.
- Se mantienen intactas las reglas 2c2 y la mecánica de Sugerir.

## Última actualización
- El cambio de posición 2c2 es una mecánica básica y gratuita: no usa monedas.
- Las piezas usan los sprites PNG existentes, dibujados al 155% del tamaño de la celda para que el contenido visible aproveche aproximadamente 70–90% de la casilla sin perder centrado.
- Los perfiles siguen siendo recursos intercambiables por jugador.


## Emotes rápidos

Se añadió un sistema de 12 emotes para 2c2, 1c1 y 1c1 local. VS IA no muestra el botón porque no hay otro jugador humano que reciba la reacción. El selector es un panel compacto y responsive: en vertical ocupa solo una esquina del tablero y en horizontal se mantiene dentro del área visible. Al enviar un emote, una copia pequeña sobresale desde la tarjeta del jugador que lo envió, sin cubrir el tablero. Enfriamiento: 2 segundos.

Los avatares, nombres y estados siguen siendo elementos dinámicos de Godot; el reloj es un único elemento dinámico por equipo; los emotes son PNG individuales.

La orientación móvil quedó en modo sensor y el stretch usa `expand` para permitir que la composición responda a vertical y horizontal.


## 1c1 Online

La opción `1c1` del menú se trata como la variante online: muestra flujo de búsqueda de rival, estado EN LÍNEA, un reloj por jugador/lado, Historial, Emotes, Rendirse y Tablas. Durante una partida online no se muestran Menú ni Reiniciar y la navegación de cancelar/volver queda bloqueada mientras la partida está activa. Al terminar la partida aparece `Volver al menú`.

La capa de red real todavía no está conectada; el flujo actual es una carcasa visual/local para validar UX y distribución antes de integrar matchmaking, sincronización autoritativa y reconexión.

## Online setup actualizado

Al tocar `2c2` o `1c1 · ONLINE` se abre un modal por encima del menú con:
- Partida pública.
- Jugar con un amigo.
- Tiempo: 10', 15' o 20'.
- Nota visible indicando que el reloj corre únicamente durante el turno activo.

`Jugar con un amigo` abre una sala privada con código, enlace, QR, regeneración de código y selector de tiempo.

Después se muestra una pantalla de matchmaking/espera. La conexión real y la sincronización de red todavía no están implementadas. El matchmaking actual es solo una simulación local con rango de rating para validar la UX y las reglas de búsqueda antes de conectar el servidor.

## Reloj

En 2c2 hay un reloj por equipo. En 1c1 hay un reloj por jugador/lado. Solo el reloj del equipo/jugador cuyo turno está activo disminuye.

### Salas privadas
Desde `2c2` o `1c1 ONLINE -> Jugar con un amigo` ahora existe tanto `Crear sala` como `Unirse a una sala`. Para unirse se puede introducir el código de 6 caracteres o pegar el enlace. La configuración de tiempo/reglas la define el anfitrión.

## Base de cuenta, progreso y ajustes

Se añadió una capa local de progreso para preparar la experiencia antes del servidor real:
- Perfil local con nombre y avatar.
- Estadísticas individuales y de pareja.
- Historial local de resultados.
- Ranking individual y ranking de parejas como estructura de interfaz/local.
- Pantalla de Copas.
- Ajustes persistentes: vibración, coordenadas del tablero, confirmación de rendición y reducción de movimiento.
- El ajuste de coordenadas se aplica directamente al tablero.
- La rendición de 1c1 muestra confirmación cuando el ajuste está activo.

El ranking mostrado sin servidor es una representación local de prueba. No se presenta como ranking global real hasta conectar la persistencia online.

## Sistema competitivo local

La base competitiva quedó separada en sistemas para poder cambiar las reglas sin rehacer la interfaz ni la futura capa online:

- **Rating individual:** representa fuerza relativa y se actualiza según resultado y diferencia de rating.
- **Rating de pareja:** cada combinación de jugador + compañero tiene su propio rating, estadísticas y racha.
- **Copas de temporada:** representan progreso y están separadas del rating.
- **Copas históricas:** conservan la suma de copas positivas acumuladas a través del tiempo.
- **Ligas:** Bronce (0), Plata (200), Oro (500), Platino (900), Diamante (1400) y Leyenda (2000). Los umbrales están centralizados para poder ajustarlos posteriormente.
- **Temporadas:** el estado actual es la Temporada 1 y la infraestructura permite iniciar una nueva temporada sin alterar ratings históricos. El reinicio no está expuesto al jugador mientras no exista una autoridad de servidor.
- **Rankings locales de prueba:** se muestran ranking por rating individual, rating de parejas y tablas de copas de temporada. Se etiquetan como locales hasta que exista persistencia global real.

### Fórmula inicial de copas

La versión actual usa una regla deliberada y aislada en `competitive_system.gd`:

- Victoria: **+7 / +10 / +13** según el rival sea más débil, similar o más fuerte.
- Tablas: **+2 / +4 / +6** con la misma lógica.
- Derrota: **-6**, excepto derrota frente a un rival 150+ puntos superior, que es **-2**.
- Las copas no pueden bajar de cero.

El rating competitivo actual usa **NEXUS V2**: expectativa tipo Elo como base, `K` adaptativo según incertidumbre/volatilidad, forma reciente e incertidumbre que vuelve a crecer con la inactividad. El rating no baja solo por dejar de jugar.

1c1 y 2c2 mantienen estados NEXUS-SOLO independientes. En 2c2, además, cada pareja tiene un NEXUS-TEAM separado: el rating individual aprende de la fuerza individual de los rivales y el NEXUS-TEAM aprende de la fuerza de la pareja rival. La sinergia de pareja está acotada y se degrada gradualmente con la inactividad.

El contrato `competitive_match_context` conserva el snapshot competitivo de una partida y permite que la futura capa online entregue ratings de participantes, pareja e incertidumbre de forma autoritativa. Mientras no exista servidor real, el matchmaking público sigue siendo una simulación local y no representa un ranking global.

### Matchmaking local

El flujo público conserva la UX actual, pero ya tiene una lógica aislada de búsqueda por rating. Comienza con un rango de **±100**, aumenta **+50 cada 2 segundos** y llega como máximo a **±400**. Esto se puede sustituir posteriormente por la búsqueda real del servidor sin cambiar la interfaz.

## Copas

Las copas ya se aplican al terminar partidas clasificadas 1c1 y 2c2. El perfil muestra copas, rating, liga, temporada e historial de cambios. En 2c2, además, la pareja recibe sus propias copas y rating.


### Plantilla visual de clasificaciones

Las interfaces de Ranking, Liga y el diseño preparado para Temporadas comparten una fila visual de Godot con espacios definidos para:
- número de clasificación;
- avatar del jugador (o dos avatares para una pareja);
- nombre;
- copas o rating según la tabla.

La plantilla es reutilizable y responsive; no depende de una imagen estática.


## Identidad de jugador
Cada cuenta local tiene un `user_id` interno único con prefijo `USR_`, separado del nombre visible. El nombre visible se limita a 10 caracteres. El ID se conserva cuando el nombre cambia y está preparado para futuras cuentas/online.

## Bots / dificultad

La modalidad VS IA ahora tiene perfiles de bot y una fuerza objetivo basada en una escala Elo aproximada. La dificultad controla aleatoriedad, ruido de selección y profundidad de evaluación en el bot local. Este Elo es un objetivo de diseño, no un rating oficialmente calibrado; la calibración contra partidas de referencia queda para una etapa posterior.

## Tanda 9 — estabilidad y distribución móvil

- Entrada táctil y mouse emulado unificados para evitar doble procesamiento en Android.
- Espera de IA dependiente del Elo con variación natural por turno; los bots no mueven instantáneamente.
- Sugerencias de bot reutilizan la interfaz cooperativa sin autoaceptarse.
- HUD optimizado: paneles y tarjetas reaccionan a cambios de estado; el ciclo periódico queda para reloj, cooldowns y viewport.
- Reacciones temporales más grandes, sin forzar el layout.
- `.nomedia` en los datos locales y recursos preparados para evitar indexación accidental como medios.
- Auditoría de rutas: no se usan DCIM/Pictures/Movies/Download para guardar assets o partidas.

## V31 — Navegación principal

La pantalla principal ahora se concentra en **Jugar** y sus cuatro modos. La navegación general utiliza un componente reutilizable con cuatro destinos: **Jugar**, **Rankings**, **Historial** y **Más**. Perfil permanece fuera de esa barra y se abre desde el avatar/nombre.

### V34 — Historial, Replay y rendimiento
El Historial muestra una sola acción contextual por partida: **Analizar partida** antes del análisis y **Ver** después. La tarjeta no muestra la lista ni el contador de jugadas; esas jugadas pertenecen al Replay.

Desde Historial, **Analizar partida** abre primero el Replay. Allí aparece un botón compacto inferior **Analizar**. Al pulsarlo se registra `analysis_viewed` y se abre una pantalla de **Tu rendimiento final**, sin incrustar el Replay. Esa pantalla incluye un acceso rápido **Ver partida**.

En el Replay de una partida ya analizada, el acceso compacto pasa a **Ver análisis**. El botón **Ver** del Historial siempre abre el Replay completo.

En vertical la navegación se presenta como barra inferior; en horizontal se transforma en rail lateral. Rankings agrupa clasificaciones, parejas, copas y la interfaz preparada de temporadas. Más queda reservado para ayuda, funciones secundarias y futuras extensiones.

El antiguo `QuickMenu` y el botón central de Cuenta fueron retirados de la escena del menú principal.

---

# V35 — Análisis y Replay interactivos

Replay y Análisis dejaron de tratarse como vídeo. El Replay usa un tablero fijo con lista de jugadas y navegación manual. El Análisis añade resumen de rendimiento, revisión interactiva y detalle de la jugada seleccionada. La clasificación/evaluación de motor queda preparada pero no se inventa hasta integrar un evaluador real.

# V36 — Estudio profesional de partida

La interfaz de Replay/Análisis fue refinada para sentirse como una herramienta de estudio de ajedrez y no como un reproductor de vídeo.

- Se eliminaron slider y controles multimedia de primera/última posición.
- La planilla de jugadas es la navegación principal: número, Blancas y Negras.
- El tablero permanece fijo mientras el jugador selecciona posiciones desde la planilla.
- Replay y Análisis comparten el mismo visor interactivo.
- Análisis presenta cabecera de resultado, rendimiento final, datos de partida, jugada seleccionada y estudio interactivo.
- `Ver partida completa` queda como acceso rápido después del rendimiento.
- En portrait se prioriza un tablero grande y usable.
- No se inventan accuracy, blunders ni evaluaciones de motor sin un evaluador real.

### V37 — Análisis como estudio de partida
- La pantalla **Análisis** deja de ser un informe largo antes del tablero.
- Se eliminan de la parte superior `Rendimiento final`, `Datos de la partida`, `Jugada seleccionada` y el botón `Ver partida completa`.
- El análisis abre directamente el estudio interactivo con tablero + lista de movimientos.
- La futura revisión automática se integrará sobre cada movimiento para clasificar/resaltar jugadas únicamente cuando exista evaluación real; no se inventan métricas.

## V38 — Revisión movimiento por movimiento

La pantalla de Análisis funciona como estudio de la partida. Las jugadas se muestran en una sola tira horizontal compacta y el tablero mantiene el foco. Se retiró la revisión heurística provisional y su `analysis_service.gd`: las clasificaciones de mejor jugada, error, precisión, etc. quedarán a cargo de un motor de ajedrez real mediante UCI, sin duplicar lógica de evaluación dentro del proyecto.

## V39 — Tira compacta y motor real

La revisión ya no usa clasificaciones heurísticas propias. Las jugadas se muestran en una sola línea horizontal desplazable y el análisis queda preparado para delegarse a un motor UCI real.

## V40 — Motor real y estudio compacto

El estudio conserva el tablero en tamaño normal y la tira de movimientos en una sola línea. Se retiró definitivamente la heurística provisional y se añadió una integración UCI con Stockfish 19 mediante `stockfish_engine.gd` + `game_review_service.gd`. El historial guarda el reporte como `engine_analysis`. La carpeta `engine/stockfish/` documenta el binario ARM64 requerido; el proyecto no finge tener un motor funcional si ese binario no está presente.

## V54 — Bucle competitivo y postpartida

- Resultado competitivo inmediato: rating/coplas ganadas o perdidas.
- Acceso directo a Analizar desde el resultado.
- El estudio abre automáticamente la última partida cuando corresponde.
- El menú principal muestra rating, liga y copas actuales bajo 2c2.
- Se mantienen intactas las reglas 2c2 y Sugerir.

## V86 — autoridad, bots y calibración NEXUS
- Rey/Dama gestionan roles respetando jerarquía; asignar su propio rango a un inferior intercambia cargos.
- Expulsión jerárquica y aprobación privada restringida a Rey/Dama.
- 20 bots con NEXUS mejor separado desde Difícil.
- Telemetría NEXUS anonimizada y laboratorio offline preparados para el servidor real.
