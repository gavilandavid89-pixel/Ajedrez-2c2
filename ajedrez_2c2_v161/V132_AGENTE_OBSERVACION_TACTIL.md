# V132 — Agente de observación táctil QA

## Objetivo
Añadir telemetría ligera de entrada táctil para investigar puntos ciegos de la interfaz y validar empíricamente el comportamiento del doble toque, sin cambiar las reglas de ajedrez ni consumir eventos de entrada.

## Cambios
- Nuevo `domain/supervision/touch_observer_agent.gd`, conectado al `SupervisorHub`.
- Registra cada pulsación/liberación táctil recibida por `GameInputController`, incluyendo coordenadas de pantalla, casilla lógica (si existe), selección actual, estado de partida y motivo de bloqueo conocido.
- Detecta dos pulsaciones próximas (ventana de 360 ms y distancia máxima de 28 px), distingue doble toque en la misma casilla y conserva los intervalos/distancias para comparar sesiones.
- Registra resultados de interacción: selección antes/después, cantidad de movimientos antes/después y si estaba activo el modo de sugerencias.
- La observación sucede antes de los guardas principales para que los toques bloqueados por promoción, turno de bot, HUD o animación no desaparezcan del diagnóstico.
- No altera turnos, selección, movimientos, reglas ni la decisión de si una entrada es válida. No toma capturas por cada toque, para reducir carga en Android.
- La bitácora existente limita eventos en memoria y rota el archivo persistente al alcanzar 1 MiB; el paquete QA ya incluye la bitácora y su segmento anterior.

## Pruebas
- V132 touch observer: **11/11**.
- V131 panel QA offline: **6/6**.
- V130 rotación del paquete QA: **4/4**.
- V129 diagnóstico offline: **6/6**.
- V128 recuperación de bitácora: **8/8**.
- V127 integración de supervisión: **15/15**.
- V126 agente de capturas: **8/8**.
- V125 agente de tablero/piezas: **7/7**.
- V124 miniagentes: **12/12**.
- Total en estas suites: **77 pruebas aprobadas, 0 fallidas**.
- Godot 4.7.2: importación del editor y arranque headless completados con código de salida 0; no se encontraron errores de script ni parseo en los registros finales.

## Cómo usarlo
1. Ejecutar el proyecto en Godot o en el dispositivo Android.
2. Reproducir la secuencia que parece fallar: seleccionar pieza, tocar destino, probar doble toque y tocar zonas próximas a controles.
3. Abrir **Diagnóstico QA (offline)** y exportar el paquete QA después de terminar la sesión.
4. Compartir el ZIP. Buscar los eventos `touch_observed`, `double_tap_observed` y `touch_action_result` para reconstruir la secuencia.

## Límites conocidos
- Aún no se ha validado en una pantalla Android física; las pruebas son automatizadas/headless y de contrato.
- La detección del doble toque es una señal diagnóstica, no una orden de juego ni prueba definitiva de un fallo. Se debe comparar con la selección y el contador de movimientos.
- Un toque que nunca llega a `GameInputController` (por ejemplo, consumido enteramente por un control UI) no puede aparecer como entrada del tablero; los registros del controlador sí pueden revelar toques que llegan al juego y quedan bloqueados.
- La observación usa coordenadas de pantalla y casillas lógicas, no graba vídeo continuo ni capturas por toque. Las capturas existentes de escenas siguen siendo bajo demanda/por hitos.
