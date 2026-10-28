# V92 — icono de jugador y marco exterior

## Cambio
- El icono de jugador del Inicio aumenta de 58x58 a 78x78.
- Se elimina el borde rectangular del botón del perfil.
- El marco seleccionado ahora se dibuja como un anillo independiente de 84x84 detrás del icono.
- El anillo queda fuera de la imagen y no cubre el avatar.
- El avatar personalizado se carga desde el perfil; si existe una imagen `user://`, se conserva.
- La racha `x🔥` se desplaza a la derecha para acompañar al icono ampliado.
- La vista previa de Identidad usa también un anillo exterior, evitando que el marco entre en la imagen.

## QA
Se hicieron comprobaciones estáticas de las dos GDScript modificadas: funciones sin duplicados y delimitadores balanceados.

No se pudo ejecutar Godot 4.7.2 en este entorno en esta pasada porque el ejecutable utilizado en las verificaciones anteriores ya no está disponible localmente y el entorno no permite descargarlo por red. Por esta razón **NO se declara QA runtime/debugger aprobado para V92**. La regla del proyecto queda pendiente de ejecutar cuando el runtime esté disponible.
