`timescale 1ns/100ps

module lab2_1_t;
    // instance ports
    reg clk;
    reg rst;
    wire [5:0] cnt;

    lab2_1 counter(clk, rst, cnt);

    always #5 clk = ~clk;

    initial begin
        clk = 1'b1;
        rst = 1'b0;

        $display("Starting the simulation");

        $monitor("clk = %b, rst = %b, cnt = %d", clk, rst, cnt);
        // test reset
        #5 rst = 1'b1;
        #5 rst = 1'b0;
        #25 rst = 1'b1;
        #25 rst = 1'b0;
        
        #5000 $finish;
    end
endmodule