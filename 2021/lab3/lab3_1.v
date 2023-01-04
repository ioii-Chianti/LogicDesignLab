module clock_divider #(parameter n = 25) (
    input clk,
    output clk_div
);
    reg [n-1:0] cnt = 0;
    wire [n-1:0] cnt_next;

    always @(posedge clk)
        cnt <= cnt_next;

    assign cnt_next = cnt + 1;
    assign clk_div = cnt[n-1];

endmodule

module lab3_1(
    input clk,
    input rst,
    input en,
    input speed,
    output reg [15:0] led
);
    // receive new clk by instances
    wire clk_24, clk_27, new_clk;
    clock_divider #(.n(24)) cd24(.clk(clk), .clk_div(clk_24));
    clock_divider #(.n(27)) cd27(.clk(clk), .clk_div(clk_27));

    assign new_clk = speed ? clk_27 : clk_24;

    always @(posedge new_clk or posedge rst) begin
        if (rst)
            led <= {16{1'b1}};
        else if (en)
            led <= ~led;
    end

endmodule
