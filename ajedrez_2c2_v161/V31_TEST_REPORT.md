# V31 — Test Report

## Proyecto

Ajedrez 2c2 · Godot 4.7.2.

## Cambios cubiertos

- Navegación principal reutilizable: Jugar / Rankings / Historial / Más.
- Perfil fuera de la barra principal.
- Jugar concentrado en los cuatro modos.
- Rankings agrupando rating, parejas, copas y temporadas preparadas.
- Más reservado para ayuda, funciones secundarias y futuras extensiones.
- Perfil/Apariencia/Reacciones mantienen su separación definida en v30.
- Rail lateral en horizontal y barra inferior en vertical.
- Acceso al perfil reposicionado fuera del rail en horizontal.

## Resultados finales ejecutados después del último cambio

| Suite | Resultado |
|---|---:|
| Base / lógica principal | 38/38 |
| Navegación V31 | 17/17 |
| Account Hub | 96/96 |
| Personalización | 14/14 |
| Menú responsive | 27/27 |
| UI regression | 51/51 |
| Entrada de perfil | 5/5 |

Además, el escaneo del proyecto con Godot 4.7.2 terminó sin errores.

## Revisión visual

Se comprobó una ejecución gráfica de Godot para Jugar en vertical y horizontal y para Rankings en horizontal. El menú principal mantiene los modos centrados, la navegación ocupa un área independiente y el perfil permanece fuera del rail lateral.

La comprobación final en un dispositivo Android físico queda para la prueba del usuario: densidad real, gestos táctiles, orientación sensor y comportamiento del sistema Android.
