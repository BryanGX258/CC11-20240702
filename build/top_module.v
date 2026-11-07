
module top_module #(parameter integer K = 3)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [7:0] cmd,
    input wire [7:0] data,
    output wire [15:0] y
);

    // Logica del circuito


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