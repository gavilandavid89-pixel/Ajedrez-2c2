# Ajedrez 2c2 V148 — Coach táctico modular

## Objetivo
Mejorar el análisis sin proveedores externos, claves API ni un modelo de lenguaje. Stockfish sigue siendo la fuente de evaluación y variantes; un módulo pequeño interpreta únicamente evidencia ya disponible.

## Modularidad
- `domain/replay/game_review_service.gd`: orquesta el análisis y agrega el informe táctico al reporte de cada jugada.
- `domain/replay/review_tactical_commentary.gd`: genera notas deterministas a partir de la posición anterior, la jugada real, las evaluaciones y la variante principal de la jugada real. No conoce la UI ni inicia procesos.
- `domain/bots/stockfish_engine.gd`: permanece como motor de cálculo y no recibe lógica de interfaz/comentarios.

## Qué informa
- Reconoce una pieza capturada mirando el tablero previo.
- Contrasta la jugada con la mejor jugada calculada por Stockfish y la pérdida de evaluación.
- Usa la PV de la búsqueda restringida a la jugada jugada para mostrar la respuesta principal calculada tras esa decisión.
- Señala cuándo la primera alternativa sobresale mucho frente a la segunda, sin inventar el motivo táctico.
- Guarda `tactical_report` estructurado por jugada para futuras tarjetas, ejercicios o filtros sin acoplarlo a la interfaz actual.

## Límite deliberado
No declara automáticamente «columna abierta», «recaptura forzada» o «pieza colgada» solo por ver una secuencia UCI. Para esas afirmaciones hay que validar las posiciones intermedias y reglas tácticas específicas; la capa actual evita presentar inferencias no demostradas como certezas. UCI se muestra como coordenadas, no notación SAN.

## Validación
Se añadieron pruebas de contrato para identificar la pieza capturada, recuperar la respuesta desde la PV de la jugada real e integrar el módulo de forma independiente. El paquete se comprueba por integridad ZIP y verificaciones estáticas. No se afirma compilación ni ejecución real en Godot porque no hay binario de Godot disponible en el entorno de trabajo.
