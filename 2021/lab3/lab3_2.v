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

module lab3_2 (
    input clk,
    input rst,
    input en,
    input dir,
    output reg [15:0] led
);

    parameter [2:0] Flashing = 3'b001;
    parameter [2:0] Shift_init = 3'b010;
    parameter [2:0] Shift = 3'b011;
    parameter [2:0] Expand_init = 3'b100;
    parameter [2:0] Expand = 3'b101;

    wire clk_25;
    clock_divider cd (clk, clk_25);

    reg [15:0] led_next;
    reg [2:0] state, state_next;
    reg [3:0] cnt, ex_left, ex_right, ex_left_next, ex_right_next;
    reg [47:0] sh_extend, sh_extend_next;

    always @(posedge clk_25 or posedge rst) begin
        if (rst) begin
            state <= Flashing;
            led <= {16{1'b1}};
        end else if (en) begin
            state <= state_next;
            led <= led_next;
            cnt <= state == Flashing ? cnt + 1 : 0;
            ex_left <= ex_left_next;
            ex_right <= ex_right_next;
            sh_extend <= sh_extend_next;
        end
    end

    always @* begin
        case (state)
            Flashing: begin
                state_next = cnt < 12 ? Flashing : Shift_init;
                led_next = led[0] ? {16{1'b0}} : {16{1'b1}};
            end
            Shift_init: begin
                state_next = Shift;
                led_next = {8{2'b10}};
                sh_extend_next[16+:16] = {8{2'b10}};
            end
            Shift: begin
                state_next = led ? Shift : Expand_init;
                sh_extend_next = dir ? sh_extend << 1 : sh_extend >> 1;
                led_next = sh_extend_next[16+:16];
            end
            Expand_init: begin
                state_next = Expand;
                led_next = 16'b0000_0001_1000_0000;
                ex_left_next = 8;
                ex_right_next = 7;
            end
            Expand: begin
                led_next = led;
                // all LEDs are on
                if (led == {16{1'b1}})
                    state_next = Flashing;
                // all LEDs are off
                else if (led == {16{1'b0}})
                    state_next = dir ? Expand : Expand_init;
                // all LEDs are not on or off
                else begin
                    state_next = Expand;
                    // a. expand
                    if (dir == 0) begin
                        led_next[ex_left + 1] = 1'b1;
                        led_next[ex_right - 1] = 1'b1;
                        ex_left_next = ex_left + 1;
                        ex_right_next = ex_right - 1;
                    end
                    // b. shrink
                    else if (dir == 1) begin
                        led_next[ex_left] = 1'b0;
                        led_next[ex_right] = 1'b0;
                        ex_left_next = ex_left - 1;
                        ex_right_next = ex_right + 1;
                    end
                end
            end
            default: // error occurs
                led_next = {4{4'b1011}};
        endcase
    end
    
endmodule