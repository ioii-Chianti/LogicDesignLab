`timescale 1ns/100ps

module lab2_2 (
    // ports
    input clk,
    input rst,
    input carA,
    input carB,
    output reg [2:0] lightA,
    output reg [2:0] lightB);

    // parameters
    parameter [5:0] S1 = 6'b001100;   // A green, B red
    parameter [5:0] S2 = 6'b010100;   // A yellow, B red
    parameter [5:0] S3 = 6'b100001;   // A red, B green
    parameter [5:0] S4 = 6'b100010;   // A red, B yellow
    // signals
    reg [5:0] state_next;
    reg [64:0] cnt;

    always @(posedge clk, posedge rst)
        if (rst == 1'b1) begin
            cnt <= 1;
            {lightA, lightB} <= S1;
        end else begin
            cnt <= {lightA, lightB} == state_next ? cnt + 1 : 1;
            {lightA, lightB} <= state_next;
        end

    always @*
        case ({lightA, lightB})
            S1:
                if ({carA, carB} == 2'b11 || {carA, carB} == 2'b10 || {carA, carB} == 2'b01 && cnt < 2 || {carA, carB} == 2'b00)
                    state_next = S1;
                else if ({carA, carB} == 2'b01 && cnt >= 2)
                    state_next = S2;
            S2:
                state_next = S3;
            S3:
                if ({carA, carB} == 2'b11 || {carA, carB} == 2'b01 || {carA, carB} == 2'b10 && cnt < 2 || {carA, carB} == 2'b00)
                    state_next = S3;
                else if ({carA, carB} == 2'b10 && cnt >= 2)
                    state_next = S4;
            S4:
                state_next = S1;
        endcase
endmodule