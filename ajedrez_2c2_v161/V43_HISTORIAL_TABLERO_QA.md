# V43 — Ajuste de tablero de Historial/Replay

- El tablero de Replay conserva geometría 1:1.
- En vertical usa el ancho real de la ventana/dispositivo como referencia, evitando que el ancho mínimo interno de la tarjeta lo haga crecer fuera de pantalla.
- En horizontal queda limitado a un tamaño cómodo y estable.
- La tira de jugadas permanece debajo del tablero en vertical.
- Se verificó en Godot 4.7.2 con viewport 390x844: tablero 358x358.
- Se generó una captura de vídeo de 5 segundos recorriendo varias posiciones del replay.
