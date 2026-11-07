

module top_module #(parameter integer K = 3)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [7:0] cmd,
    input wire [7:0] data,
    output wire [15:0] y
);

    // CLOCK DIVIDER DE 3 HZ
    wire clk_3hz;

    CLOCK_DIVIDER DIVISOR (
        .clk(clk),
        .clk_3hz(clk_3hz)
    );

    // REGISTRO SERIAL DE 5 BITS
    wire Q0, Q1, Q2, Q3, Q4;

    registro_serial_5bits REGISTRO (
        .CLK(clk_3hz),
        .RST(rst),
        .EN(en),
        .START(cmd[0]),
        .VALID(cmd[1]),
        .BIT_IN(cmd[2]),
        .Q0(Q0),
        .Q1(Q1),
        .Q2(Q2),
        .Q3(Q3),
        .Q4(Q4)
    );

    // XOR ORIGINAL DE 5 BITS
    wire RESULTADO_XOR;

    XOR_5BITS XOR_PARIDAD (
        .A(Q0),
        .B(Q1),
        .C(Q2),
        .D(Q3),
        .E(Q4),
        .RESULTADO(RESULTADO_XOR)
    );

    // MAQUINA DE ESTADOS
    wire FIN_TRAMA;

    MAQUINA_ESTADOS_5BITS CONTROL (
        .CLK(clk_3hz),
        .RST(rst),
        .EN(en),
        .START(cmd[0]),
        .VALID(cmd[1]),
        .FIN_TRAMA(FIN_TRAMA)
    );

    // CALCULAR PARIDAD DE LOS 4 DATOS
    wire PARIDAD_CALCULADA;
    wire OK;
    wire GUARDAR;

    xor XOR_DATOS (
        PARIDAD_CALCULADA, Q0, Q1, Q2, Q3
    );

    // XNOR: COMPARAR CON EL QUINTO BIT
    xnor XNOR_CONFIRMACION (
        OK, PARIDAD_CALCULADA, cmd[2]
    );

    // AND: CONFIRMAR GRABACION
    and AND_GRABAR (
        GUARDAR, OK, FIN_TRAMA
    );

    // REGISTRO DE SALIDA DE 4 BITS
    wire N0, N1, N2, N3;

    REGISTRO_4BITS REG_SALIDA (
        .CLK(clk_3hz),
        .RST(rst),
        .OK(GUARDAR),

        .D0(Q3),
        .D1(Q2),
        .D2(Q1),
        .D3(Q0),

        .Q0(N0),
        .Q1(N1),
        .Q2(N2),
        .Q3(N3)
    );

    // SALIDA PROVISIONAL DEL REGISTRO
    assign y = {12'b0, N3, N2, N1, N0};

endmodule


// clock divider de 3 hz provicional 
    module CLOCK_DIVIDER (
    input wire clk,
    output reg clk_3hz = 1'b0
);

    reg [23:0] contador = 0;

    always @(posedge clk) begin
        if (contador == 8333332) begin
            contador <= 0;
            clk_3hz <= ~clk_3hz;
        end
        else begin
            contador <= contador + 1'b1;
        end
    end
    endmodule

    
module registro_serial_5bits (
    input wire CLK,
    input wire RST,
    input wire EN,
    input wire START,
    input wire VALID,
    input wire BIT_IN,

    output wire Q0, Q1, Q2, Q3, Q4
);

    reg [2:0] contador;
    reg recibiendo;

    wire CAPTURAR;
    wire BORRAR;

    assign CAPTURAR = EN & VALID & recibiendo;
    assign BORRAR = RST | (EN & START & ~recibiendo);

    // CONTROL DE LOS 5 BITS
    always @(posedge CLK) begin
        if (RST) begin
            contador <= 0;
            recibiendo <= 0;
        end
        else if (EN) begin
            if (!recibiendo) begin
                if (START) begin
                    contador <= 0;
                    recibiendo <= 1;
                end
            end
            else if (VALID) begin
                if (contador == 4) begin
                    contador <= 0;
                    recibiendo <= 0;
                end
                else
                    contador <= contador + 1'b1;
            end
        end
    end

    // CINCO FLIP-FLOPS TIPO D

    FLIP_FLOP_D FF0 (
        .CLK(CLK), .RST(BORRAR),
        .EN(CAPTURAR), .D(BIT_IN), .Q(Q0)
    );

    FLIP_FLOP_D FF1 (
        .CLK(CLK), .RST(BORRAR),
        .EN(CAPTURAR), .D(Q0), .Q(Q1)
    );

    FLIP_FLOP_D FF2 (
        .CLK(CLK), .RST(BORRAR),
        .EN(CAPTURAR), .D(Q1), .Q(Q2)
    );

    FLIP_FLOP_D FF3 (
        .CLK(CLK), .RST(BORRAR),
        .EN(CAPTURAR), .D(Q2), .Q(Q3)
    );

    FLIP_FLOP_D FF4 (
        .CLK(CLK), .RST(BORRAR),
        .EN(CAPTURAR), .D(Q3), .Q(Q4)
    );

endmodule

module FLIP_FLOP_D (
    input wire CLK,
    input wire RST,
    input wire EN,
    input wire D,
    output reg Q
);

    always @(posedge CLK) begin
        if (RST)
            Q <= 1'b0;
        else if (EN)
            Q <= D;
    end

endmodule
// 5 xor de paridad que toman la salida del registro y la entrada de datos para generar un bit de paridad
module XOR_5BITS (
    input wire A, B, C, D, E,
    output wire RESULTADO
);

    wire X1, X2, X3;

    xor XOR1 (X1, A, B);
    xor XOR2 (X2, C, D);
    xor XOR3 (X3, X1, X2);
    xor XOR4 (RESULTADO, X3, E);

endmodule

module REGISTRO_4BITS (
    input wire CLK,
    input wire RST,
    input wire OK,
    input wire D0, D1, D2, D3,
    output reg Q0, Q1, Q2, Q3
);

    always @(posedge CLK) begin
        if (RST) begin
            Q0 <= 1'b0;
            Q1 <= 1'b0;
            Q2 <= 1'b0;
            Q3 <= 1'b0;
        end
        else if (OK) begin
            Q0 <= D0;
            Q1 <= D1;
            Q2 <= D2;
            Q3 <= D3;
        end
    end

endmodule

module MAQUINA_ESTADOS_5BITS (
    input wire CLK,
    input wire RST,
    input wire EN,
    input wire START,
    input wire VALID,
    output wire FIN_TRAMA
);

    // ESTADOS
    localparam ESPERA = 3'd0;
    localparam BIT1   = 3'd1;
    localparam BIT2   = 3'd2;
    localparam BIT3   = 3'd3;
    localparam BIT4   = 3'd4;
    localparam BIT5   = 3'd5;

    reg [2:0] estado;

    always @(posedge CLK) begin

        if (RST)
            estado <= ESPERA;

        else if (EN) begin

            case (estado)

                ESPERA: begin
                    if (START)
                        estado <= BIT1;
                end

                BIT1: begin
                    if (VALID)
                        estado <= BIT2;
                end

                BIT2: begin
                    if (VALID)
                        estado <= BIT3;
                end

                BIT3: begin
                    if (VALID)
                        estado <= BIT4;
                end

                BIT4: begin
                    if (VALID)
                        estado <= BIT5;
                end

                BIT5: begin
                    if (VALID)
                        estado <= ESPERA;
                end

                default:
                    estado <= ESPERA;

            endcase
        end
    end

    // SE ACTIVA AL LLEGAR EL QUINTO BIT
    assign FIN_TRAMA =
        (estado == BIT5) & VALID & EN & ~RST;

endmodule
