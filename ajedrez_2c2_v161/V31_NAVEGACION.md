# V31 — Navegación principal y separación de funciones

## Objetivo

Reducir la cantidad de opciones visibles en la pantalla principal y preparar una navegación de app móvil que funcione en vertical y horizontal sin mezclar Perfil con las secciones principales.

## Navegación principal

La barra reutilizable está en `ui/main_navigation.gd` y tiene cuatro destinos:

1. **Jugar** — modos 2c2, 1c1 online, VS IA y 1c1 local.
2. **Rankings** — clasificaciones individuales, parejas, copas y diseño preparado de temporadas.
3. **Historial** — partidas guardadas, replay y análisis preparado.
4. **Más** — funciones secundarias y espacio deliberado para funciones futuras.

Perfil no forma parte de esta barra. Su entrada permanece en el avatar/nombre situado fuera de la navegación principal.

## Distribución responsive

- En vertical: barra inferior de cuatro destinos.
- En horizontal: rail lateral compacto.
- El contenido reserva espacio para la navegación para evitar solapamientos.
- El acceso al Perfil se reposiciona fuera del rail en horizontal.

## Más

Actualmente contiene:

- Ayuda y controles.
- Logros preparados para una futura activación.
- Eventos preparados para una futura activación.
- Un espacio explícito para futuras funciones.
- Salida de la aplicación.

No se colocan Ajustes, Apariencia ni Reacciones aquí porque pertenecen al Perfil.

## Rankings

Copas quedó integrada dentro de Rankings. Las temporadas siguen siendo solo interfaz preparada y no activan todavía reglas de temporada.

## Organización

Se eliminó el `QuickMenu` anterior y el botón central antiguo de Cuenta. La navegación se construye con un único componente reutilizable para evitar duplicación de lógica y estilos entre escenas.

## Validación

- Godot 4.7.2: escaneo de proyecto sin errores.
- Navegación V31: 17/17.
- Menú responsive V26 actualizado: 27/27.
- Refinamiento V28 actualizado: 23/23.
- Entrada de Perfil: 5/5.
- Account Hub: 96/96.
- UI visual/responsive: 1496/1496.
- Regresión de UI: 51/51.
- Personalización: 14/14.
- Rendimiento del perfil: 3/3.

Las capturas de ventana de Godot verificaron visualmente Jugar en vertical y horizontal y Rankings en horizontal. La validación final en el dispositivo Android del usuario sigue siendo necesaria para confirmar tacto, densidad y orientación reales.
