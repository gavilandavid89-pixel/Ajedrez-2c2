# Seguridad de assets y galería

Los assets visuales del juego viven bajo `res://` y se empaquetan como recursos de la aplicación; no se copian a la galería pública durante el flujo normal.

Los datos persistentes usan `user://ajedrez_2c2`. Al crear sus directorios, `StorageManager` coloca un `.nomedia` en la raíz, `cache` y `backup`. Esto protege incluso el caso en que Android aloje `user://` en una ubicación basada en almacenamiento de la aplicación.

No se usan rutas públicas como `DCIM`, `Pictures`, `Movies` o `Download` en los scripts del proyecto.
