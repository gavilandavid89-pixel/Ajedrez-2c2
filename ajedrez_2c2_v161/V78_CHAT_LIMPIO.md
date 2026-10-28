# V78 — Chat limpio + revancha compacta

## Cambios

### Chat de partida
- Se elimina el título contextual `Chat con el rival` / `Chat de la partida`.
- El campo usa únicamente `Escribir` como placeholder.
- La `X` de cierre queda en la misma posición, pero como botón plano/directo, sin plantilla de panel alrededor.
- El historial de mensajes y la lógica de chat compartido no cambian.
- 1c1 mantiene comunicación con su rival.
- 2c2 mantiene un único historial de partida compartido por aliados y rivales.

### Solicitud de revancha
- Se elimina el texto auxiliar `Puedes aceptar o rechazar`.
- La notificación conserva únicamente el mensaje de Juanito y los botones `✓` / `×`.
- Se ajustó el tamaño del texto para que el mensaje completo quepa en móvil.

## Capturas validadas
- `/mnt/data/v78_chat_1c1.png`
- `/mnt/data/v78_chat_2c2.png`
- `/mnt/data/v78_rematch.png`

## QA Godot 4.7.2
- Chat/Rematch: **12/12**
- Core: **39/39**
- Arquitectura modular: **59/59**
- Importación/editor headless: **exit 0**

Godot sigue mostrando al cerrar los runners 3 ObjectDB instances leaked y 1 resource in use. No se introdujo código de captura permanente; el script temporal usado para las capturas fue eliminado antes de empaquetar.
