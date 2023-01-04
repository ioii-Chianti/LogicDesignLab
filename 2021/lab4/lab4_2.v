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

module lab4_2 (
    input clk,
    input rst,
    input en,    // switch
    input input_number,
    input enter,
    input count_down,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output led0
);
    // preprocess pushbuttons
    wire db_input_number, input_number_;
    debounce d1(.pb_debounced(db_input_number), .clk(clk), .pb(input_number));
    onepulse o1(.pb_debounced(db_input_number), .clk(clk), .pb_1pulse(input_number_));
    wire db_enter, enter_;
    debounce d2(.pb_debounced(db_enter), .clk(clk), .pb(enter));
    onepulse o2(.pb_debounced(db_enter), .clk(clk), .pb_1pulse(enter_));
    wire db_count_down, count_down_;
    debounce d3(.pb_debounced(db_count_down), .clk(clk), .pb(count_down));
    onepulse o3(.pb_debounced(db_count_down), .clk(clk), .pb_1pulse(count_down_));

    // States and signals (for 7-seg, for flags in each state)
    parameter [2:0] Direction = 3'b000;
    parameter [2:0] Number_init = 3'b001;
    parameter [2:0] Number = 3'b010;
    parameter [2:0] Count_init = 3'b011;
    parameter [2:0] Count = 3'b100;
    parameter [2:0] Stop = 3'b101;
    reg [2:0] state, state_next;

    reg [3:0] display, digit_0, digit_1, digit_2, digit_3;
    reg [3:0] digit_0_next, digit_1_next, digit_2_next, digit_3_next;

    reg countDown, countDown_next;    // in Direction
    reg [1:0] index, index_next;      // in Number
    reg [3:0] target_0, target_1, target_2, target_3;    // in Count

    // clock
    wire clk_main, clk_pSec, clk_seg;
    clock_divider #(.n(23)) cd1(.clk(clk), .clk_div(clk_pSec));
    clock_divider #(.n(14)) cd2(.clk(clk), .clk_div(clk_seg));
    assign clk_main = state == Count ? clk_pSec : clk;

    // update states, digits, state flags
    always @(posedge clk_main, posedge rst) begin
        if (rst) begin
            state <= Direction;
            digit_0 <= 15;
            digit_1 <= 15;
            digit_2 <= 15;
            digit_3 <= 15;
        end else begin
            state <= state_next;
            digit_0 <= digit_0_next;
            digit_1 <= digit_1_next;
            digit_2 <= digit_2_next;
            digit_3 <= digit_3_next;
            // update state signals in corresponding state
            if (state == Direction)
                countDown <= countDown_next;
            if (state == Number_init || state == Number)
                index <= index_next;
            if (state == Count_init) begin
                target_0 <= digit_0;
                target_1 <= digit_1;
                target_2 <= digit_2;
                target_3 <= digit_3;
            end
        end
    end

    // State and digit transition
    always @* begin
        case (state)
            Direction: begin
                state_next = enter_ ? Number_init : Direction;
                countDown_next = count_down_ ? !countDown : countDown;
                digit_0_next = 15;
                digit_1_next = 15;
                digit_2_next = 15;
                digit_3_next = 15;
            end
            Number_init: begin
                state_next = Number;
                index_next = 3;
                digit_0_next = 0;
                digit_1_next = 0;
                digit_2_next = 0;
                digit_3_next = 0;
            end
            Number: begin
                state_next = Number;
                index_next = index;
                digit_0_next = digit_0;
                digit_1_next = digit_1;
                digit_2_next = digit_2;
                digit_3_next = digit_3;
                if (enter_ && index > 0)
                    index_next = index - 1;
                else if (enter_ && index == 0)
                    state_next = Count_init;
                // push input_number_ to increase digit_<index>
                if (input_number_) begin
                    case (index)
                        3: digit_3_next = !digit_3;
                        2: digit_2_next = digit_2 < 5 ? digit_2 + 1 : 0;
                        1: digit_1_next = digit_1 < 9 ? digit_1 + 1 : 0;
                        0: digit_0_next = digit_0 < 9 ? digit_0 + 1 : 0;
                    endcase
                end
            end
            Count_init: begin
                state_next = Count;
                if (countDown == 0) begin    // Count up, digits initialize to 0
                    digit_0_next = 0;
                    digit_1_next = 0;
                    digit_2_next = 0;
                    digit_3_next = 0;
                end else if (countDown == 1) begin    // Count down, digits won't change
                    digit_0_next = digit_0;
                    digit_1_next = digit_1;
                    digit_2_next = digit_2;
                    digit_3_next = digit_3;
                end
            end
            Count: begin
                state_next = Count;
                digit_0_next = digit_0;
                digit_1_next = digit_1;
                digit_2_next = digit_2;
                digit_3_next = digit_3;

                if (countDown == 0 && digit_0 == target_0 && digit_1 == target_1 && digit_2 == target_2 && digit_3 == target_3
                  || countDown == 1 && digit_0 == 0 && digit_1 == 0 && digit_2 == 0 && digit_3 == 0)
                    state_next = Stop;
                // --- Counting Part
                else if (en) begin
                    // count up
                    if (countDown == 0) begin
                        // 0. pointSec
                        if (digit_0 < 9)
                            digit_0_next = digit_0 + 1;
                        else begin
                            digit_0_next = 0;
                            // 1. second
                            if (digit_1 < 9)
                                digit_1_next = digit_1 + 1;
                            else begin
                                digit_1_next = 0;
                                // 2. ten second
                                if (digit_2 < 5)
                                    digit_2_next = digit_2 + 1;
                                else begin
                                    digit_2_next = 0;
                                    // 3. minute
                                    digit_3_next = 1;
                                end
                            end
                        end
                    end
                    // count down
                    else if (countDown == 1) begin
                        // 0. pointSec
                        if (digit_0 > 0)
                            digit_0_next = digit_0 - 1;
                        else begin
                            digit_0_next = 9;
                            // 1. second
                            if (digit_1 > 0)
                                digit_1_next = digit_1 - 1;
                            else begin
                                digit_1_next = 9;
                                // 2. ten second
                                if (digit_2 > 0)
                                    digit_2_next = digit_2 - 1;
                                else begin
                                    digit_2_next = 5;
                                    // 3. minute
                                    digit_3_next = 0;
                                end
                            end
                        end
                    end
                end // --- end Counting Part
            end
            Stop: begin
                state_next = rst ? Direction : Stop;
                digit_0_next = digit_0;
                digit_1_next = digit_1;
                digit_2_next = digit_2;
                digit_3_next = digit_3;
            end
        endcase
    end
    
    // 7-segment display and look-up table
    always @(posedge clk_seg) begin
        case (DIGIT)
            4'b1110: begin
                display <= digit_1;
                DIGIT <= 4'b1101;
            end
            4'b1101: begin
                display <= digit_2;
                DIGIT <= 4'b1011;
            end
            4'b1011: begin
                display <= digit_3;
                DIGIT <= 4'b0111;
            end
            4'b0111: begin
                display <= digit_0;
                DIGIT <= 4'b1110;
            end
            default: begin
                display <= digit_0;
                DIGIT <= 4'b1110;
            end
        endcase
    end

    always @* begin
        case (display)
            // 0 ~ 9
            4'd0: DISPLAY = 7'b100_0000;
            4'd1: DISPLAY = 7'b111_1001;
            4'd2: DISPLAY = 7'b010_0100;
            4'd3: DISPLAY = 7'b011_0000;
            4'd4: DISPLAY = 7'b001_1001;
            4'd5: DISPLAY = 7'b001_0010;
            4'd6: DISPLAY = 7'b000_0010;
            4'd7: DISPLAY = 7'b111_1000;
            4'd8: DISPLAY = 7'b000_0000;
            4'd9: DISPLAY = 7'b001_0000;
            // dash
            4'd15: DISPLAY = 7'b011_1111;
            default: DISPLAY = 7'b111_1111;
        endcase
    end

    assign led0 = countDown;

endmodule