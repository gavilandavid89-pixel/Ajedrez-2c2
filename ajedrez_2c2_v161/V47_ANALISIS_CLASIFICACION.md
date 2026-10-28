# V47 — Análisis contextual y clasificación de jugadas

## Objetivo

El análisis de replay usa Stockfish como motor y una capa propia de clasificación. Stockfish no produce etiquetas como «Brillante» o «Genial»; devuelve evaluaciones, PV y variantes UCI. La clasificación se construye encima de esos datos.

## Clasificaciones

- **Excelente**: pérdida de evaluación menor de 20 cp.
- **Muy bien**: 20–44 cp.
- **Bien**: 45–79 cp.
- **Imprecisa**: 80–119 cp.
- **Error**: 120–199 cp.
- **Error grave**: 200 cp o más.
- **Genial**: jugada prácticamente óptima en una posición crítica, con separación clara frente a las alternativas principales.
- **Brillante**: jugada prácticamente óptima que además presenta un candidato real a sacrificio de pieza, no deja una posición mala y no procede de una posición ya completamente ganada.
- **Oportunidad perdida**: el rival acaba de cometer un error importante y la jugada analizada deja escapar una oportunidad claramente ganadora.

Los umbrales de pérdida anteriores son una calibración interna del juego basada en pérdida de evaluación de Stockfish. No se presenta como una copia exacta del Expected Points de Chess.com, porque ese modelo también depende del rating.

## Brillante

La documentación pública actual de Chess.com (9 de febrero de 2026) define Brilliant como una jugada mejor o casi mejor que además contiene un buen sacrificio de pieza; también exige que la posición posterior no sea mala y que la partida no fuera ya completamente ganada sin la jugada. Esta implementación adopta esa estructura, pero detecta el sacrificio de forma conservadora mediante la posición y las reglas locales.

Una pieza no se marca como sacrificio solo por moverse a una casilla atacada: el candidato debe ser una pieza de valor de caballo/alfil o superior, quedar realmente atacable y tener una captura legal disponible. Después Stockfish debe confirmar que la jugada es prácticamente óptima.

## Genial

Se busca una jugada crítica. MultiPV=3 permite comparar la principal con alternativas. Si la jugada es prácticamente óptima y la segunda alternativa queda claramente por detrás, puede convertirse en Genial. Esto evita llamar Genial a cualquier jugada simplemente buena.

## Coach

El coach aparece de forma contextual. No habla en cada movimiento. En movimientos normales puede permanecer oculto. En movimientos destacados muestra:

- clasificación;
- explicación concreta de la jugada;
- mejor continuación cuando está disponible;
- pérdida aproximada de evaluación en errores;
- motivo especial en Genial/Brillante/Oportunidad perdida.

La tira de movimientos conserva el color de cada clasificación y sirve como navegación principal.

## Colores

- Error grave / Error: rojo.
- Imprecisa: naranja.
- Bien / Muy bien / Excelente: verdes progresivos.
- Genial: azul.
- Brillante: violeta.

El tablero resalta origen y destino de la jugada seleccionada con el color de su clasificación.

## Stockfish

El análisis usa `MultiPV 3` para obtener alternativas y un segundo `searchmoves` restringido a la jugada realizada. La ejecución del binario Android ARM64 sigue pendiente de validación en un runtime Android ARM64 real; el entorno de pruebas Linux x86_64 no puede ejecutar ese ELF ARM64.
