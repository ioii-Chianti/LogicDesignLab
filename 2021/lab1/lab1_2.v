`timescale 1ns/100ps

module lab1_2 (a, b, aluctr, d);
    input [3:0] a;
    input [1:0] b;
    input [1:0] aluctr;
    output reg [3:0] d;
    wire [3:0] temp1, temp2;   // instance 的 output signal 必須是 wire type

    lab1_1 a1(.a(a), .b(b), .dir(0), .d(temp1));
    lab1_1 a2(.a(a), .b(b), .dir(1), .d(temp2));
    
    always @*
        case (aluctr)
            2'b00: d = temp1;
            2'b01: d = temp2;
            2'b10: d = a + b;
            2'b11: d = a - b;
        endcase
endmodule