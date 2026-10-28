# Ajedrez 2c2 · V70 — Social, Clubes, Amigos y Más

## Objetivo
Extender la organización móvil definida en V69 sin convertir Inicio en un panel saturado. La navegación inferior queda reservada para Inicio, Club, Amigos y Más; las pantallas internas son independientes.

## Cambios
- Más ahora es una pantalla independiente y alberga Ajustes, Identidad, Experiencia, Rankings, Copas, NEXUS y Ayuda.
- Ajustes se retiró del encabezado de Inicio y del encabezado de Perfil; la ruta principal es Más → Ajustes.
- Amigos muestra exclusivamente relaciones aceptadas. `FriendsService.request_from_match()` queda preparado para conectarse a la pantalla de victoria/derrota.
- Clubes dispone de búsqueda, creación, paginación incremental al llegar al final del scroll y pantalla de detalle.
- Crear club permite iconos de la aplicación o selección desde Galería, descripción opcional y acceso Público / Privado con NEX / NEXUS.
- Un club seleccionado se muestra una vez en su pantalla de detalle; al unirse/crear, queda como club activo y la navegación Club conduce directamente a su chat.
- Chat de club muestra icono y nombre arriba, miembros, perfil social + solicitud de amistad y desafíos amistosos 1c1/2c2.
- Los desafíos llevan contrato explícito `competitive=false`, `affects_rating=false`, `affects_cups=false`, `affects_pair_points=false`, `affects_nexus=false`.
- 1c1 requiere 1 aceptación adicional al creador; 2c2 requiere 3 aceptaciones adicionales al creador.

## QA
- Godot 4.7.2 importación: OK, sin parser errors.
- Core: 39/39.
- Home scroll: 17/17.
- Navegación: 18/18.
- Account Hub: 149/149.
- Personalización: 14/14.
- UI Regression: 53/53.
- Responsive Touch: 30/30.
- Orientation/Layout: 22/22.
- V57 presentación 1c1: 2/2 (actualizado al nuevo Home).
- V28: 23/23.
- NEXUS-TEAM: 27/27.
- Module contracts V67: 20/20.
- Chess domain contracts: 10/10.
- Arquitectura + Social contract: 61/61.
- Social: 35/35.

## Nota
Los warnings de `ObjectDB`, recursos o audio dummy aparecen por el entorno headless existente y no generaron errores de script ni fallos funcionales.
