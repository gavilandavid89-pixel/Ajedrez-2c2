# Ajedrez 2c2 — V135: auditoría estática integral y comparación de interfaz

## Resumen ejecutivo

Se auditó el paquete V134 antes de modificarlo. El objetivo de esta ronda fue detectar defectos verificables, corregir problemas de interfaz/diagnóstico de bajo riesgo y preservar las reglas de ajedrez y la lógica de turnos 2c2.

**Resultado:** se corrigieron cinco problemas concretos/de robustez, se mejoraron los objetivos táctiles del aviso de revancha y se añadió una suite de contratos V135. No se afirma que el proyecto compile ni que la suite de Godot haya pasado: en este entorno no se encontró el ejecutable de Godot 4.7.2, por lo que la validación de motor y la prueba visual real siguen pendientes.

## Alcance inspeccionado

- 786 archivos de archivo (821 entradas contando directorios).
- 243 scripts GDScript.
- Escenas principales de inicio, selección de modo, partida, tablero, HUD, ajustes online, chat, clubes, perfil, historial y resultado.
- Controlador de entrada táctil, servicios de supervisión QA, registro de agentes, exportador ZIP, layout responsive y herramienta de calibración de bots.
- Referencias `res://` en scripts/configuración/escenas y rutas externas declaradas por escenas/recursos.

## Hallazgos y cambios

### 1. Menú de inicio: espacio vacío acumulativo en actualizaciones de revancha — corregido

`ui/screens/mode_menu.gd` creaba `TopBreathingRoom` dentro de `_refresh_rematch_banner()`. Cada actualización del aviso podía añadir otro nodo de espacio al `content_box`, desplazando progresivamente el contenido principal. Se eliminó esa creación desde el refresco del aviso.

### 2. Aviso de revancha: búsqueda de un hijo pendiente de eliminación — corregido

El refresco llamaba a `queue_free()` sobre los hijos antiguos y luego el posicionamiento seleccionaba el primer hijo por índice. Como `queue_free()` difiere la eliminación hasta el final del frame, el primer hijo podía ser el nodo antiguo y no la fila nueva. Ahora se desacopla el hijo antes de programar su eliminación y se busca la fila actual por el nombre `RematchRow`.

### 3. Entrada táctil: estado compartido entre varios dedos — corregido por contrato

El controlador mantenía una sola casilla de origen, pero no asociaba ese estado a un índice de puntero. Una segunda pulsación podía sobrescribir el origen del primer dedo y una liberación de otro dedo podía completar la secuencia equivocada. Ahora se conserva el índice del puntero activo y solo ese puntero puede completar el toque/arrastre. Los dedos secundarios se ignoran para la interacción del tablero; no se cambiaron las reglas de movimiento ni los turnos.

### 4. Exportador QA: podía informar éxito con un ZIP incompleto — corregido

El exportador ignoraba errores de `close_file()` y `ZIPPacker.close()` y seguía devolviendo `ok: true` si alguna entrada fallaba al escribirse. Ahora registra las entradas fallidas, comprueba el cierre de cada archivo y el cierre del ZIP, y devuelve `ok: false` con un código de error si el paquete queda incompleto. Se conserva el máximo de 40 capturas y el valor predeterminado de 12.

### 5. Herramienta auxiliar de calibración: escritura en `res://` — corregido

`domain/bots/calibration_runner.gd` intentaba guardar el resultado en `res://bot_calibration_results.json`, que puede ser de solo lectura en una instalación exportada. Ahora usa `user://bot_calibration_results.json`; se actualizó la documentación de esa herramienta auxiliar.

### 6. Objetivos táctiles del aviso de revancha — mejorados

Los botones de aceptar/rechazar pasan a 44×44 unidades lógicas, y el texto reserva espacio para no solaparse con ellos. Esto no certifica todos los controles del juego: el escaneo estático encontró otros tamaños compactos en distintos paneles, varios de ellos iconos decorativos o controles secundarios. Deben revisarse visualmente en dispositivo antes de cambiar sus dimensiones en bloque.

## Comparación con aplicaciones de ajedrez móviles

Referencias públicas consultadas:
- Chess.com destaca navegación móvil inferior para entrar rápidamente a Play, Puzzles y Lessons, y permite personalizar tablero, piezas y fondo.
- Lichess ofrece una experiencia móvil con partidas, puzzles, análisis y personalización del tablero/piezas, manteniendo sus funciones principales accesibles.

### Lo que ya encaja con buenas prácticas

- La partida y el tablero son el núcleo de la experiencia; existe layout separado para vertical/horizontal.
- La navegación principal inferior está separada de las acciones de la partida.
- La interfaz 2c2 tiene que comunicar cuatro plazas, equipo/compañero y estado de turno, algo que los clientes 1c1 no necesitan resolver del mismo modo.
- Las escenas de HUD, chat, menú de acciones y tablero están separadas en recursos distintos, lo que facilita refinar el diseño sin reescribir las reglas.

### Diferencias y mejoras recomendadas

1. **Jerarquía visual:** mantener el tablero como elemento dominante durante la partida y relegar chat, reacciones y acciones menos frecuentes a paneles compactos.
2. **Legibilidad de 2c2:** diferenciar claramente compañero y rivales mediante posición, color y estado; no depender solo del color para indicar turno o conexión.
3. **Controles táctiles:** verificar en Android todos los botones pequeños y zonas donde los paneles se acercan al tablero. En esta ronda se mejoró el aviso de revancha, pero no se redimensionaron indiscriminadamente iconos, avatares y separadores.
4. **Menú adaptable:** revisar el espacio superior reservado y el scroll en pantallas cortas, casi cuadradas y con escalado de fuente del sistema. No se cambió ese bloque sin poder comparar una captura de la versión actual en ejecución.
5. **Personalización:** como mejora posterior, ofrecer una selección compacta de temas de tablero y piezas, con vista previa, sin cargar múltiples texturas pesadas a la vez en dispositivos modestos.
6. **Feedback de movimiento:** conservar un resaltado de origen/destino claro y mensajes de error breves; los avisos temporales no deben tapar casillas o controles esenciales.
7. **Accesibilidad:** revisar contraste del texto secundario, etiquetas accesibles de botones con solo icono y objetivos táctiles con el dispositivo real.

## Validaciones estáticas ejecutadas

- Cero referencias `res://` rotas encontradas en código/configuración/escenas/recursos tras los cambios.
- Cero rutas `res://` inexistentes encontradas en declaraciones de recursos externos de `.tscn` y `.tres`.
- Contratos estáticos nuevos para: ausencia del espacio acumulativo, reconstrucción segura de la fila de revancha, tamaño de botones de revancha, asociación del puntero activo, rechazo de liberaciones de otro dedo, detección de fallos al cerrar ZIP y límite de capturas.
- Revisión del archivo ZIP final con prueba de integridad.

## Validación pendiente (no afirmar como aprobada)

1. Abrir el proyecto en Godot 4.7.2 y comprobar el panel `Output` tras importar.
2. Ejecutar `tests/v135_system_audit_tests.gd`.
3. Reejecutar las suites de entrada táctil V132/V133, integración de supervisión y regresión de UI.
4. Probar en pantalla Android real: toque normal, arrastre, segundo dedo, toques cerca de botones, cambio de orientación y reapertura repetida del aviso de revancha.
5. Exportar un ZIP QA real y verificarlo con `ZIPReader`.
6. Comparar capturas actuales en 360×800, 390×844, 720×720 y 844×390.

## Límite de la auditoría

Este informe separa defectos encontrados por inspección estática de comportamientos que requieren ejecución real. No se modificaron reglas de ajedrez, turnos, equipos, compañero, legalidad de movimientos ni resultados de partidas.
