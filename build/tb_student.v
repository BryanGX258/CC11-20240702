`timescale 1ns/1ps

// Testbench del receptor serial de 4 bits + paridad par.
// Comprueba dos instancias: K=3 y K=5.
// IMPORTANTE: el diseno del estudiante incluye un divisor de 3 Hz.
// Para no esperar millones de ciclos de simulacion, SOLO en este
// testbench se fuerza el cable interno clk_3hz a un reloj de prueba.
// No hay que modificar top_module.v para ejecutar estas pruebas.

module tb_student;

    reg clk = 1'b0;
    reg clk_prueba = 1'b0;
    reg rst = 1'b0;
    reg en = 1'b0;
    reg [7:0] cmd = 8'b0;
    reg [7:0] data = 8'h00;

    wire [15:0] y3;
    wire [15:0] y5;

    integer pruebas = 0;
    integer errores = 0;
    integer i;
    reg [3:0] ultima_nota = 4'd0;

    // Reloj de entrada y reloj acelerado SOLO para la simulacion.
    always #5  clk = ~clk;
    always #20 clk_prueba = ~clk_prueba;

    top_module #(.K(3)) DUT3 (
        .clk(clk), .rst(rst), .en(en),
        .cmd(cmd), .data(data), .y(y3)
    );

    top_module #(.K(5)) DUT5 (
        .clk(clk), .rst(rst), .en(en),
        .cmd(cmd), .data(data), .y(y5)
    );

    // Enviar una combinacion de entradas durante un ciclo de recepcion.
    // Las entradas cambian en flanco negativo y se revisan 1 ns
    // despues del flanco positivo, como exige la especificacion.
    task automatic paso;
        input r, e, s, v, b;
        begin
            @(negedge clk_prueba);
            rst = r;
            en = e;
            cmd = {5'b00000, b, v, s};
            @(posedge clk_prueba);
            #1;
        end
    endtask

    task automatic comprobar;
        input [3:0] nota_esperada;
        input done_esperado, error_esperado, busy_esperado;
        input [8*65-1:0] descripcion;
        reg [15:0] esperado;
        begin
            esperado = {9'b0, busy_esperado, error_esperado,
                        done_esperado, nota_esperada};
            pruebas = pruebas + 1;
            if ((y3 !== esperado) || (y5 !== esperado)) begin
                errores = errores + 1;
                $display("FALLO: %0s", descripcion);
                $display("  esperado = %04h  K3 = %04h  K5 = %04h",
                         esperado, y3, y5);
            end else begin
                $display("OK: %0s | y=%04h", descripcion, esperado);
            end
        end
    endtask

    // Transmitir 4 bits LSB primero y, finalmente, el de paridad.
    task automatic enviar_trama;
        input [3:0] nota_enviada;
        input bit_paridad;
        integer j;
        begin
            // START tiene prioridad: VALID=1 aqui NO consume dato.
            paso(0, 1, 1, 1, 1);
            comprobar(ultima_nota, 0, 0, 1, "START+VALID: inicia sin capturar");

            for (j = 0; j < 4; j = j + 1) begin
                paso(0, 1, 0, 1, nota_enviada[j]);
                comprobar(ultima_nota, 0, 0, 1, "Recibiendo bit de datos");
            end

            paso(0, 1, 0, 1, bit_paridad);
            if ((^nota_enviada) == bit_paridad) begin
                ultima_nota = nota_enviada;
                comprobar(ultima_nota, 1, 0, 0, "Trama con paridad correcta");
            end else begin
                comprobar(ultima_nota, 0, 1, 0, "Error: conserva nota anterior");
            end

            // DONE y ERROR deben apagarse en el flanco siguiente.
            paso(0, 1, 0, 0, 0);
            comprobar(ultima_nota, 0, 0, 0, "Pulso DONE/ERROR desaparece");
        end
    endtask

    initial begin
        $dumpfile("ondas.vcd");
        $dumpvars(0, tb_student);

        // Se acelera la simulacion SIN CAMBIAR EL CODIGO DEL DUT.
        // 'force' existe solo en el testbench, no en top_module.v.
        force DUT3.clk_3hz = clk_prueba;
        force DUT5.clk_3hz = clk_prueba;

        // RESET inicial y prioridad de RESET incluso con EN=0.
        paso(1, 0, 1, 1, 1);
        ultima_nota = 0;
        comprobar(0, 0, 0, 0, "Reset inicial con EN=0");

        // CASO NOMINAL: numero 9 y su paridad correcta.
        enviar_trama(4'd9, 1'b0);

        // PARIDAD INCORRECTA: conservar la nota 9.
        enviar_trama(4'd9, 1'b1);

        // LAS 16 NOTAS: 0 a 15 con paridad correcta.
        for (i = 0; i < 16; i = i + 1)
            enviar_trama(i[3:0], ^i[3:0]);

        // PAUSAS: EN=0 y VALID=0 no consumen bits.
        paso(0, 1, 1, 0, 0);
        comprobar(ultima_nota, 0, 0, 1, "Inicio de prueba de pausas");

        paso(0, 0, 0, 1, 1);
        comprobar(ultima_nota, 0, 0, 1, "EN=0 congela recepcion");

        paso(0, 1, 0, 0, 1);
        comprobar(ultima_nota, 0, 0, 1, "VALID=0 no consume bit");

        // START durante BUSY se ignora (VALID=0).
        paso(0, 1, 1, 0, 0);
        comprobar(ultima_nota, 0, 0, 1, "START ignorado durante BUSY");

        // Enviar 9: 1,0,0,1; paridad 0.
        paso(0, 1, 0, 1, 1);
        comprobar(ultima_nota, 0, 0, 1, "Dato 1 de trama pausada");
        paso(0, 1, 0, 1, 0);
        paso(0, 1, 0, 1, 0);
        paso(0, 1, 0, 1, 1);
        comprobar(ultima_nota, 0, 0, 1, "Cuatro datos recibidos");

        // Pausa entre el cuarto dato y la paridad.
        paso(0, 0, 0, 1, 1);
        comprobar(ultima_nota, 0, 0, 1, "Pausa EN=0 antes de paridad");
        paso(0, 1, 0, 0, 1);
        comprobar(ultima_nota, 0, 0, 1, "Pausa VALID=0 antes de paridad");
        paso(0, 1, 0, 1, 0);
        ultima_nota = 4'd9;
        comprobar(ultima_nota, 1, 0, 0, "Trama con pausas recibida correctamente");

        // DONE debe apagarse aunque EN=0.
        paso(0, 0, 0, 0, 0);
        comprobar(ultima_nota, 0, 0, 0, "DONE se apaga con EN=0");

        // ERROR debe apagarse aunque EN=0.
        paso(0, 1, 1, 0, 0);
        paso(0, 1, 0, 1, 1);
        paso(0, 1, 0, 1, 0);
        paso(0, 1, 0, 1, 0);
        paso(0, 1, 0, 1, 1);
        paso(0, 1, 0, 1, 1); // 9 con paridad incorrecta
        comprobar(ultima_nota, 0, 1, 0, "ERROR por paridad incorrecta");
        paso(0, 0, 0, 0, 0);
        comprobar(ultima_nota, 0, 0, 0, "ERROR se apaga con EN=0");

        // RESET a mitad de trama.
        paso(0, 1, 1, 0, 0);
        paso(0, 1, 0, 1, 1);
        comprobar(ultima_nota, 0, 0, 1, "Recepcion en proceso antes de reset");
        paso(1, 1, 0, 0, 0);
        ultima_nota = 0;
        comprobar(0, 0, 0, 0, "Reset a mitad de trama borra todo");

        // Un VALID sin START no debe comenzar otra trama.
        paso(0, 1, 0, 1, 1);
        comprobar(0, 0, 0, 0, "VALID aislado no inicia trama");

        $display("\nRESULTADOS: %0d comprobaciones, %0d fallos", pruebas, errores);
        if (errores != 0)
            $fatal(1, "La simulacion detecto errores.");
        else
            $display("TODAS LAS PRUEBAS PROPIAS PASARON (K=3 y K=5).");
        $finish;
    end
endmodule
