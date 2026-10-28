# V73 — Resultado ↔ Tablero + corona compartida + solicitud de amistad

Cambios:
- La pantalla final conserva el regreso al tablero mediante la X, con tooltip `Volver al tablero`.
- El tablero terminado puede volver a abrir la pantalla final mediante el botón existente `🏆 Resultado`.
- Los ganadores se muestran juntos bajo una única corona grande compartida.
- Se eliminó la corona individual pequeña de cada avatar.
- El `+` de amistad queda pequeño pero visible sobre el avatar.
- Al tocar `+`: cambia a `✔`, hace una breve animación de escala, se desvanece y desaparece.
- Si ya existe una amistad o solicitud pendiente, el `+` no vuelve a aparecer al reconstruir la pantalla.
- No se añadieron textos relacionados con clips, previews o duración de vídeo al juego.
- No se modificaron reglas de 1c1/2c2.

QA:
- Se realizaron comprobaciones estáticas sobre la implementación modificada.
- El binario Godot 4.7.2 utilizado en la QA anterior no está disponible en esta sesión, por lo que no se declara una ejecución de Godot como pasada en esta revisión.
