# Pruebas de persistencia — v20

Todas las pruebas se ejecutaron con **Godot 4.7.2.stable**.

## Persistencia

- Guardado atómico: OK
- Backup inicial: OK
- Rotación de backup: OK
- Recuperación desde backup: OK
- Caché fresca: OK
- Caché reconstruible: OK
- Cola offline y coalescing: OK
- Adaptador de nube sin transporte real: OK

**Storage tests: 18/18**

**Runtime con autoloads reales: 10/10**

## Regresión del proyecto

- Base: 9/9
- Competitivo: 24/24
- Matchmaking: 8/8
- Bots: 39/39
- Integración bots: 6/6
- Perfil/UI: 9/9
- Tandas 5–7: 23/23
- UI regression: 51/51
- Tanda 8: 5372/5372
- Main scene: arranque correcto, código de salida 0

Los tests de estrés de Tanda 8 siguen mostrando al salir algunas advertencias del arnés de prueba por instancias liberadas; no provocan fallos de aserciones ni código de salida distinto de cero.
