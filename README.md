# Receptor serial de notas con paridad par

**Asignatura:** Sistemas Digitales — Code Challenge CC11  
**Reto:** Receptor serial de notas con paridad  
**Valor:** 25 puntos  
**Estudiante:** [Nombre completo]  
**Matrícula:** [Tu matrícula]  
**Correo:** [Tu correo institucional]

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

## 4. Arquitectura implementada hasta el momento

El diseño se ha construido por módulos, usando registros de tipo D y compuertas lógicas:

- **`CLOCK_DIVIDER`**: genera una señal de aproximadamente 3 Hz a partir de una entrada de 50 MHz. Es un elemento **provisional de demostración**.
- **`registro_serial_5bits`**: recibe secuencialmente los cinco bits mediante cinco Flip-Flops tipo D y controla el desplazamiento con `START`, `VALID` y `EN`.
- **`FLIP_FLOP_D`**: define un Flip-Flop tipo D con habilitación y reset síncrono.
- **`MAQUINA_ESTADOS_5BITS`**: recorre los estados de espera y recepción de los cinco bits; genera `FIN_TRAMA` y `BUSY`.
- **`XOR_5BITS`**: calcula la paridad de las cinco salidas del registro, como bloque de observación. En la versión actual no gobierna directamente la escritura.
- **`XOR_DATOS` y `XNOR_CONFIRMACION`**: comprueban la paridad de los cuatro datos contra el quinto bit que está llegando.
- **`AND_GRABAR`**: genera la habilitación `GUARDAR` únicamente si la paridad coincide y está llegando la quinta muestra válida.
- **`REGISTRO_4BITS`**: conserva la última nota aceptada mediante cuatro Flip-Flops.

**Orden de bits:** antes del quinto flanco válido, los cuatro datos recibidos están en `Q3`, `Q2`, `Q1` y `Q0` del registro serial. Por eso el registro de salida toma `D0=Q3`, `D1=Q2`, `D2=Q1` y `D3=Q0` en ese flanco.

## 5. Prioridades y casos límite

- **Reset:** debe borrar el estado de recepción, los registros, `done`, `error` y `busy` en el siguiente flanco positivo de `clk`.
- **`start` y `valid` juntos:** si el receptor está en reposo, `start` inicia la trama, pero no captura ese bit.
- **`start` mientras `busy=1`:** se ignora.
- **`valid=0`:** no se consume ninguna muestra; el circuito sigue esperando.
- **`en=0`:** pausa la recepción. `done` y `error` deben borrarse igualmente en cada flanco.
- **Paridad incorrecta:** se conserva la última nota válida.
- **Sin timeout:** la recepción puede permanecer pausada indefinidamente.

**Caso límite destacado:** si ya se almacenó correctamente el número `9` y después llega una trama de paridad incorrecta, la salida `y[3:0]` debe seguir representando `9` mientras `error` se activa durante un ciclo.

## 6. Estado del proyecto y aspectos pendientes

**Estado actual: implementación por etapas; todavía no se ha validado la entrega con todas las pruebas automáticas.**

La versión de desarrollo utiliza `clk_3hz` como reloj del receptor para facilitar una demostración visual. **Esto no cumple la especificación final**, que exige usar **solo `clk`** como reloj del módulo evaluado. Antes de entregar, se debe retirar el reloj derivado del funcionamiento del receptor y verificar todos los requisitos temporales.

También está pendiente crear o completar `tb_student.v`, ejecutar las simulaciones y documentar los resultados reales. No se declara ninguna prueba como superada hasta ejecutarla.

## 7. Simulación y pruebas

El docente solicita **Icarus Verilog 12 o posterior**. Desde la raíz del repositorio, cuando exista el archivo `tb_student.v`, ejecutar:

```bash
iverilog -g2012 -s tb_student -o sim top_module.v tb_student.v
vvp sim
```

No subir el ejecutable `sim` al repositorio.

### Plan de pruebas automáticas

| Grupo | Caso que debe comprobarse | Resultado |
|---|---|---|
| G1 | Reset a mitad de trama y después de nota válida | Pendiente |
| G2 | Las 16 notas posibles (0–15) con paridad correcta | Pendiente |
| G3 | Paridad incorrecta y conservación de nota anterior | Pendiente |
| G4 | Prioridad de `start` frente a `valid` e ignorar `start` mientras `busy` | Pendiente |
| G5 | Pausas con `valid=0` y `en=0` | Pendiente |
| G6 | 900 ciclos pseudoaleatorios reproducibles y verificación por ciclo | Pendiente |

**Parámetros `K` que se deben probar:** `3` y `5`.  
**Resultados obtenidos:** pendientes de ejecutar y registrar.

## 8. Historial de commits y avances

El docente exige **al menos cuatro commits significativos** que demuestren el progreso real. Completar esta tabla con los **hashes verdaderos** de Git; no inventar avances ni hashes.

| Etapa | Commit (hash) | Avance realizado |
|---|---|---|
| 1. Estructura | `[pendiente]` | Interfaz del módulo, estructura inicial y plan. |
| 2. Implementación parcial | `[pendiente]` | Registro serial, compuertas, registros y control progresivo. |
| 3. Pruebas y depuración | `[pendiente]` | Testbench, ejecución de pruebas y correcciones. |
| 4. Solución final | `[pendiente]` | Cumplimiento del contrato, documentación y pruebas reproducibles. |

Para obtener los commits reales:

```bash
git log --oneline
```

Para consultar el hash completo del último commit:

```bash
git rev-parse HEAD
```

## 9. Entrega

El repositorio debe contener al menos:

```text
verilog-CC11-20240702/
├── top_module.v
├── tb_student.v
└── README.md
```

**Repositorio:** https://github.com/BryanGX258/verilog-CC11-20240702  
**Hash completo del commit final evaluable:** `[pendiente]`

> Antes de entregar, actualizar los datos del estudiante, la tabla de commits y los resultados de simulación. El código debe cumplir la interfaz exacta y permitir al docente reproducir las pruebas.
