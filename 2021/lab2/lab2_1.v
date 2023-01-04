`timescale 1ns/100ps

module lab2_1 (clk, rst, cnt);
    input clk, rst;
    output reg [5:0] cnt;   // current number
    reg [5:0] cnt_next;
    reg [127:0] n, n_next;
    reg type;   // type of current sequence

    parameter upward = 1'b0;
    parameter downward = 1'b1;

    always @(posedge clk, posedge rst)
        // if reset then count from 0 to 63
        if (rst == 1'b1) begin
            cnt <= 0;
            n <= 1;
            type <= upward;
        end else begin
            cnt <= cnt_next;
            // check if needs to change sequence
            if (type == upward && cnt_next == 63 || type == downward && cnt_next == 0) begin
                n <= 1;
                type <= !type;
            end else
                n <= n_next;
        end

    always @* begin
        // update next index n into buffer
        n_next = n + 1;
        // update next number into buffer
        case (type)
            upward:   cnt_next = cnt > n ? cnt - n : cnt + n;
            downward: cnt_next = cnt - 2 ** (n-1);
        endcase
    end
endmodule