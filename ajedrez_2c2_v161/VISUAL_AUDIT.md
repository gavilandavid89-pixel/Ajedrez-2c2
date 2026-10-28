# Auditoría visual y responsive — Ajedrez 2c2

Fecha: 2026-10-01
Motor: Godot 4.7.2.stable

## Problemas encontrados y corregidos

### 1. Controles que se salían o desaparecían en horizontal
En tamaños compactos la barra inferior tenía botones auxiliares con un mínimo vertical de 40 px, aunque el layout compacto reservaba 32 px para esa fila. Esto producía un desborde de unos 4 px y podía hacer que el último control pareciera recortado.

Corrección: los botones auxiliares de la fila compacta usan 32 px de alto y la fila superior conserva 40 px para las acciones principales. La barra compacta usa dos filas cuando no caben en una sola.

### 2. Barra superior en pantallas estrechas
En anchos pequeños, los textos "Menú" y "Reiniciar" competían con el título.

Corrección: se usan iconos compactos (`‹` y `↻`) por debajo del umbral responsive y el título se limita al espacio restante.

### 3. Tarjetas de jugadores
La tarjeta es reutilizable y recalcula avatar, información y tamaños de texto cuando cambia de tamaño. El reloj no pertenece a la tarjeta: hay un único reloj por equipo/lado.

La auditoría ahora verifica que:
- ninguna tarjeta se solape con otra;
- la información no invada el avatar;
- el nombre quepa en su label;
- las tarjetas permanezcan dentro del panel del equipo;
- no exista un nodo de reloj dentro de `PlayerCard`.

### 4. Equipos y tablero
Se comprueban las posiciones relativas entre:
- cabecera del equipo;
- reloj del equipo;
- grid de jugadores;
- etiqueta de turno;
- tablero;
- barra inferior.

En vertical el tablero conserva el ancho disponible y se centra en X. En horizontal se mantienen columnas laterales para los equipos y el tablero queda despejado.

### 5. Modos de juego
La auditoría recorre 2c2, 1c1, VS IA y 1c1 Local. Se verifica que chat, sugerir, cambio y tablas solo aparezcan en 2c2; VS IA no muestra herramientas de equipo.

### 6. Menú de modos y carga
Se comprueba que los cuatro modos y el botón de salida estén dentro de la pantalla, sin solaparse, tanto en vertical como en horizontal. La pantalla de carga también se comprueba contra los límites del viewport.

### 7. Entrada real del tablero
La regresión responsive simula pulsaciones en `e2` y `e4` usando las coordenadas calculadas del tablero y verifica que el movimiento se registre y la selección se limpie. Esto evita una falsa sensación de "se ve bien pero no se puede jugar".

## Matriz responsive

Se auditan estos viewports:

- 360×640
- 390×844
- 412×915
- 720×1280
- 800×480
- 1024×600
- 1280×720
- 1920×1080

Para cada viewport se revisan los cuatro modos.

## 8. Cuenta, ranking, copas y apariencia en móvil
En 360×640 se detectó que la ficha de perfil podía crecer por encima del viewport y que la previsualización de temporadas podía forzar el ancho del contenido.

Corrección: el cuerpo de las páginas se adapta al ancho disponible; la previsualización usa una cuadrícula de columnas responsive; la información larga de perfil usa ajuste/recorte controlado.

También se verificó que ranking, ligas y temporadas usan filas preparadas para posición + avatar + nombre + copas/rating, y parejas con dos avatares. Apariencia mantiene tablero y piezas separados para futura personalización.

## 9. Configuración online en móvil
Se detectaron textos del título y controles inferiores que podían salirse en 360×640.

Corrección: tamaños y posiciones compactas para la pantalla principal, crear/unirse a sala y parámetros de sala. La versión revisada mantiene todos los controles dentro del modal.

## 10. Modal de fin de partida
Se detectó un problema real: el modal original medía 420×280 de forma fija y quedaba parcialmente fuera de un móvil de 360 px; además, los controles de la partida seguían visibles detrás.

Corrección: modal responsive, botones de igual ancho y separación fija, y ocultación de controles de partida al finalizar. Se añadió regresión específica para comprobar límites y solapamientos.

## 11. Retrabajo del tablero compacto
Al agrandar el tablero en teléfonos pequeños, los textos de movimientos/estado podían quedar por debajo de la barra inferior.

Corrección: se reajustó el espacio reservado del layout compacto para que el tablero siga siendo considerablemente mayor que la versión original, pero movimientos, estado y barra de acciones tengan áreas separadas.

## Matriz responsive

Se auditan estos viewports:

- 360×640
- 390×844
- 412×915
- 720×1280
- 800×480
- 1024×600
- 1280×720
- 1920×1080

Para cada viewport se revisan los cuatro modos.

## Resultado final

- Núcleo de regresión: **38 OK / 0 fallos**
- Cuenta/interfaz: **72 OK / 0 fallos**
- Setup online: **37 OK / 0 fallos**
- Regresión UI clásica + fin de partida: **51 OK / 0 fallos**
- Sistema competitivo: **24 OK / 0 fallos**
- Matchmaking local: **8 OK / 0 fallos**
- Perfil/UI: **9 OK / 0 fallos**
- Bots/dificultad: **39 OK / 0 fallos**
- Integración bot-partida: **6 OK / 0 fallos**
- Auditoría visual responsive: **1514 OK / 0 fallos**

Además se hicieron capturas gráficas reales con render OpenGL/llvmpipe en móvil, vertical grande, horizontal y VS IA. Los mensajes ALSA del contenedor corresponden al dispositivo de audio inexistente del entorno de pruebas; Godot cae al driver de audio dummy.
