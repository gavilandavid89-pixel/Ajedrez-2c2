# V34 — Reporte de validación

## Cambio principal
- Historial sin lista/contador de jugadas.
- `Analizar partida` es la única acción del registro antes del análisis.
- `Ver` es la única acción del registro después del análisis y abre el Replay completo.
- Replay: `Analizar` compacto antes del análisis y `Ver análisis` después.
- Análisis: muestra rendimiento final y botón rápido `Ver partida`; no incrusta el Replay.
- Entrar al Replay no marca el análisis; solo pulsar `Analizar` cambia `analysis_viewed`.

## Godot 4.7.2
- V34 historial: **16/16**
- Base: **38/38**
- Navegación V31: **17/17**
- Entrada de Perfil: **5/5**
- Personalización: **14/14**
- Integración de Historial: **5/5**
- Almacenamiento: **18/18**

## Render
Se realizó captura gráfica con Godot 4.7.2 + Xvfb para Historial, Replay y Análisis en 720x1280. El renderer utilizó Mesa llvmpipe; los avisos de audio/vsync pertenecen al entorno de prueba y no forman parte del proyecto.
