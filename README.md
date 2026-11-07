# Receptor serial de notas con paridad par

**Asignatura:** Sistemas Digitales — Code Challenge CC11  
**Reto:** Receptor serial de notas con paridad  
**Valor:** 25 puntos  
**Estudiante:** [Bryan Miguel Santana Varela]  
**Matrícula:** [2024-0702]  
**Correo:** [20240702@itla.edu.do]

## 1. Objetivo

Diseñar en **Verilog 2001** un receptor serial que reciba **cuatro bits de datos y un quinto bit de paridad**, compruebe la **paridad par** y actualice la última nota válida únicamente si la comprobación es correcta.

El receptor no verifica si el **valor decimal** es par o impar: comprueba si la **cantidad de bits en 1**, contando el bit de paridad, es par.

## 2. Funcionamiento general

1. Con `en=1`, una señal `start=1` en reposo inicia una nueva recepción. Ese mismo flanco no consume un dato aunque `valid=1`.
2. El receptor espera muestras válidas (`valid=1` y `en=1`) y recibe los **cuatro bits de datos, comenzando por el menos significativo (LSB)**, mediante una sola línea serial.
3. La quinta muestra válida contiene el bit de paridad enviado por el transmisor.
4. La lógica XOR calcula la paridad de los cuatro datos y una XNOR compara ese resultado con el quinto bit. Si coinciden, la paridad es correcta.
5. Si la trama es correcta, el registro de salida conserva el nuevo número de cuatro bits y se activa `done`. Si la paridad es incorrecta, se activa `error` y permanece la última nota válida.
6. `busy` indica que hay una recepción en curso. Las señales `done` y `error` deben durar un ciclo de reloj.

**Ejemplo:** para transmitir el número decimal **9** (`1001`), los bits se envían en este orden: `1, 0, 0, 1`, seguidos del bit de paridad `0`. El XOR de los cinco bits vale `0`, así que la nota aceptada es `1001`.

## 3. Interfaz obligatoria

```verilog
module top_module #(parameter integer K = 3)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [7:0] cmd,
    input wire [7:0] data,
    output wire [15:0] y
);
```

### Entradas

| Señal | Descripción |
|---|---|
| `clk` | Reloj principal. |
| `rst` | Reset síncrono, activo alto y prioritario. |
| `en` | Habilita o pausa la recepción. |
| `cmd[0]` | `start`: inicia una trama. |
| `cmd[1]` | `valid`: indica que el bit serial debe capturarse. |
| `cmd[2]` | `bit_serial`: bit de entrada, uno por muestra válida. |
| `cmd[7:3]` | Bits ignorados. |
| `data[7:0]` | Entrada no utilizada en este reto. |

El parámetro `K` permanece en la interfaz por requisito del docente, aunque este reto no lo utiliza. Se evaluará con `K=3` y `K=5`.

### Salidas requeridas

| Señal | Descripción |
|---|---|
| `y[3:0]` | Última nota válida almacenada. |
| `y[4]` | `done`: recepción correcta. |
| `y[5]` | `error`: error de paridad. |
| `y[6]` | `busy`: recepción activa. |
| `y[15:7]` | Siempre `0`. |

