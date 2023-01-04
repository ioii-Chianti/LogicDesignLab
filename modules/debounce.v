module debounce (
    output pb_debounced,
    input pb,
    input clk
);
    reg [3:0] shift;
    always @(posedge clk) begin
        shift[3:1] <= shift[2:0];
        shift[0] <= pb;
    end

    assign pb_debounced = (shift == 4'b1111) ? 1'b1 : 1'b0;
endmodule