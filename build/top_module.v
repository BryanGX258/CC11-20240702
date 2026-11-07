
module top_module #(parameter integer K = 3)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [7:0] cmd,
    input wire [7:0] data,
    output wire [15:0] y
);

    // Logica del circuito

    // CLOCK DIVIDER DE 3 HZ
    wire clk_3hz;

    CLOCK_DIVIDER DIVISOR (
        .clk(clk),
        .clk_3hz(clk_3hz)
    );

    // SALIDAS DEL REGISTRO
    wire Q0, Q1, Q2, Q3, Q4;

    // REGISTRO SERIAL DE 5 BITS
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

    // SALIDAS PROVISIONALES PARA VER LOS 5 BITS
    assign y = {11'b0, Q4, Q3, Q2, Q1, Q0};


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
