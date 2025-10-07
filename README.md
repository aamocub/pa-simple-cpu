# pa-simple-cpu
CPU simple para la asignatura PA

## Diseño

Componentes ha desarrollar:
1. Registor general
2. Unidad de control: Manejar excepciones, sabe el estado entero del procesador y decide que señales de control
activar en función de esa información.
3. ALU
4. LSU? (Ahora no deberia de hacer falta dado que todo es monociclo)
5. Controlador de memoria? (Probablemente no hace falta)

## Testbench

Si hicieramos este procesador como toca, deberiamos de hacer un testbench por cada uno de los módulos que hayamos diseñado, pero jeje.

## Excepciones y control del procesador