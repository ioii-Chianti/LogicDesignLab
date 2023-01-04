`timescale 1ns/100ps

module lab1_1 (a, b, dir, d);
    input [3:0] a;
    input [1:0] b;
    input dir;
    output reg [3:0] d;

    always @*
        case (dir)
            0: d = a << b;
            1: d = a >> b;
        endcase
endmodule