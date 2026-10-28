# V108 — Auditoría global de distribución UI

## Objetivo
Corregir la sensación de que los títulos, botones y listas están pegados a la parte superior; ampliar controles y asegurar que la barra lateral horizontal no tape el contenido.

## Cambios
- Inicio: más separación vertical entre perfil, título, acciones principales, estadísticas e historial. El contenido sigue desplazable para no cortar secciones en pantallas cortas.
- Perfil y botón de más opciones: áreas táctiles más amplias; posición específica para vertical y horizontal.
- Navegación: barra inferior y botones más grandes en vertical; barra lateral más ancha y botones más fáciles de tocar en horizontal.
- Componentes sociales compartidos: títulos, botones y áreas táctiles más grandes.
- Amigos, clubes, perfil, cuenta, creación/detalle de clubes, miembros y chat: mayor margen superior en vertical y adaptación al rotar.
- Más opciones: tarjetas más altas, separación entre grupos y desplazamiento inicial inferior para no empezar pegado al borde superior.
- Preparación de partida local y contra bots: margen superior adaptable.

## Verificación
- Godot 4.7.2: importación y análisis de scripts completados.
- Pruebas de lógica: 39/39 correctas.
- Pruebas de orientación/layout: 22/22 correctas.
- Auditoría de flujos: 18/18 pantallas auditadas, 250 interacciones revisadas.
- Capturas y vídeos grabados desde la aplicación ejecutada con Godot en escritorio Linux, en resoluciones de prueba vertical y horizontal. No equivale a una prueba en dispositivo Android físico.
