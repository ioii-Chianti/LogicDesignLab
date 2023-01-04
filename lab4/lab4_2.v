module clock_divider #(parameter n = 27) (
    input wire  clk,
    output wire clk_div  
);
    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule

module lab4_2 ( 
    input wire clk,
    input wire rst,
    input wire start,
    input wire direction,
    input wire increase,
    input wire decrease,
    input wire select,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output wire max,
    output wire min,
    output wire d2,
    output wire d1,
    output wire d0
 ); 
    // preprocess pushbuttons
    wire db_start, _start;
    debounce d3(.pb_debounced(db_start), .clk(clk), .pb(start));
    one_pulse o1(.pb_in(db_start), .clk(clk), .pb_out(_start));
    wire db_direction, _direction;
    debounce d4(.pb_debounced(db_direction), .clk(clk), .pb(direction));
    one_pulse o2(.pb_in(db_direction), .clk(clk), .pb_out(_direction));

    wire db_increase, _increase;
    debounce d5(.pb_debounced(db_increase), .clk(clk), .pb(increase));
    one_pulse o3(.pb_in(db_increase), .clk(clk), .pb_out(_increase));
    wire db_decrease, _decrease; 
    debounce d6(.pb_debounced(db_decrease), .clk(clk), .pb(decrease));
    one_pulse o4(.pb_in(db_decrease), .clk(clk), .pb_out(_decrease));
    wire db_select, _select;
    debounce d7(.pb_debounced(db_select), .clk(clk), .pb(select));
    one_pulse o5(.pb_in(db_select), .clk(clk), .pb_out(_select));

    // State and next signals
    parameter Initial = 2'b00;
    parameter Stop = 2'b01;
    parameter Count = 2'b10;
    reg [1:0] state, state_next, selectedDigit, selectedDigit_next;
    reg [9:0] cnt = 50, cnt_next;
    reg dir, dir_next;
    assign max = (cnt == 999);
    assign min = (cnt == 0);
    assign d0 = (selectedDigit == 0);
    assign d1 = (selectedDigit == 1);
    assign d2 = (selectedDigit == 2);

    wire clk_7segment, clk_count, clk_cnt;
    clock_divider #(.n(14)) cd0 (.clk(clk), .clk_div(clk_7segment));
    clock_divider #(.n(23)) cd1 (.clk(clk), .clk_div(clk_count));
    assign clk_cnt = (state == Stop) ? clk : clk_count; 

    // Update signals w/ different frequency
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= Initial;
            dir <= 0;
            selectedDigit <= 0;
        end else begin
            state <= state_next;
            dir <= dir_next;
            selectedDigit <= selectedDigit_next;
        end
    end

    always @(posedge clk_cnt, posedge rst) begin
        if (rst)
            cnt <= 50;
        else
            cnt <= cnt_next;
    end

    // State transition
    always @* begin
        cnt_next = cnt;
        case (state)
            Initial: begin
                if (rst) state_next = Initial;
                else if (_start) state_next = Stop;
                else state_next = Initial;
                selectedDigit_next = 0;
                cnt_next = 50;
                dir_next = dir;
            end
            Stop: begin
                // state
                if (rst)
                    state_next = Initial;
                else if (_start)
                    state_next = Count;
                else
                    state_next = Stop;
                // select
                if (_select)
                    selectedDigit_next = (selectedDigit == 2) ? 0 : selectedDigit + 1;
                else
                    selectedDigit_next = selectedDigit;
                // cnt
                cnt_next = cnt;
                if (_increase) begin
                    case (selectedDigit)
                        0: cnt_next = (cnt % 10 == 9) ? cnt : cnt + 1;
                        1: cnt_next = (cnt / 10 % 10 == 9) ? cnt : cnt + 10;
                        2: cnt_next = (cnt / 100 == 9) ? cnt : cnt + 100;
                    endcase
                end else if (_decrease) begin
                    case (selectedDigit)
                        0: cnt_next = (cnt % 10 == 0) ? cnt : cnt - 1;
                        1: cnt_next = (cnt / 10 % 10 == 0) ? cnt : cnt - 10;
                        2: cnt_next = (cnt / 100 == 0) ? cnt : cnt - 100;
                    endcase
                end
                // dir
                dir_next = dir;
            end
            Count: begin
                // state
                if (rst)
                    state_next = Initial;
                else if (_start)
                    state_next = Stop;
                else
                    state_next = Count;
                // dir
                if (_direction)
                    dir_next = ~dir;
                else
                    dir_next = dir;
                // select
                selectedDigit_next = selectedDigit;
                // cnt
                if (dir == 0 && cnt < 999)
                    cnt_next = cnt + 1;
                else if (dir == 1 && cnt > 0)
                    cnt_next = cnt - 1;
            end
        endcase
    end

    reg [3:0] display;
    reg [3:0] digit_0, digit_1, digit_2, digit_3;

    always @* begin
        if (state == Initial) begin
            digit_0 = 10;
            digit_1 = 10;
            digit_2 = 10;
            digit_3 = 10;
        end else begin
            digit_0 = cnt % 10;
            digit_1 = cnt / 10 % 10;
            digit_2 = cnt / 100;
            if (state == Count)
                digit_3 = (dir == 0) ? 14 : 15;
            else if (state == Stop) begin
                if (db_direction == 0)
                    digit_3 = 10;
                else if (db_direction == 1)
                    digit_3 = (dir == 0) ? 14 : 15;
            end
        end
    end

    always @(posedge clk_7segment) begin
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
            4'd10: DISPLAY = 7'b011_1111;
            // arrows
            4'd14: DISPLAY = 7'b101_1100;   // up
            4'd15: DISPLAY = 7'b110_0011;   // down
            default: DISPLAY = 7'b111_1111;
        endcase
    end

endmodule
