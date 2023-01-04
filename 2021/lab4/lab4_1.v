module clock_divider #(parameter n = 25) (  // 越大越慢
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

module lab4_1 (
    input clk,
    input rst,
    input en,
    input dir,
    input speed_up,
    input speed_down,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output max,
    output min
    );

    // preprocess pushbuttons
    wire db_en, en_;
    debounce d2(.pb_debounced(db_en), .clk(clk), .pb(en));
    onepulse o2(.pb_debounced(db_en), .clk(clk), .pb_1pulse(en_));
    wire dir_;
    debounce d3(.pb_debounced(dir_), .clk(clk), .pb(dir));
    wire db_speed_up, speed_up_;
    debounce d4(.pb_debounced(db_speed_up), .clk(clk), .pb(speed_up));
    onepulse o4(.pb_debounced(db_speed_up), .clk(clk), .pb_1pulse(speed_up_));
    wire db_speed_down, speed_down_;
    debounce d5(.pb_debounced(db_speed_down), .clk(clk), .pb(speed_down));
    onepulse o5(.pb_debounced(db_speed_down), .clk(clk), .pb_1pulse(speed_down_));

    // State and next signals
    parameter Reset = 2'b00;
    parameter Pause = 2'b01;
    parameter Count = 2'b10;
    reg [1:0] state, state_next;
    reg [6:0] cnt, cnt_next;
    reg [1:0] speed, speed_next;
    assign max = cnt == 99;
    assign min = cnt == 0;

    reg [3:0] display;
    reg [3:0] digit_0, digit_1, digit_2, digit_3;

    always @* begin
        digit_0 = cnt % 10;
        digit_1 = cnt / 10;
        if (state != Pause)
            digit_2 = (dir_ == 0) ? 14 : 15;
        else
            digit_2 = 14;
        digit_3 = speed;
    end

    // clocks
    wire clk_25, clk_24, clk_23, clk_seg;
    clock_divider #(.n(25)) cd1(.clk(clk), .clk_div(clk_25));
    clock_divider #(.n(24)) cd2(.clk(clk), .clk_div(clk_24));
    clock_divider #(.n(23)) cd3(.clk(clk), .clk_div(clk_23));
    clock_divider #(.n(14)) cd4(.clk(clk), .clk_div(clk_seg));
    reg clk_speed;

    always @(speed) begin
        case (speed)
            2'b00: clk_speed = clk_25;
            2'b01: clk_speed = clk_24;
            2'b10: clk_speed = clk_23;
        endcase
    end

    // Update signals w/ different frequency
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= Reset;
            speed <= 0;
        end else begin
            state <= state_next;
            speed <= speed_next;
        end
    end

    always @(posedge clk_speed, posedge rst) begin
        if (rst)
            cnt <= 0;
        else
            cnt <= cnt_next;
    end

    // State transition
    always @* begin
        cnt_next = cnt;
        speed_next = speed;
        case (state)
            Reset: begin
                state_next = Pause;
                cnt_next = 0;
                speed_next = 0;
            end
            Pause: begin
                // state
                if (rst)
                    state_next = Reset;
                else if (en_)
                    state_next = Count;
                else
                    state_next = Pause;
                // cnt
                cnt_next = cnt;
                // speed
                if (speed_up_ && speed < 2)
                    speed_next = speed + 1;
                else if (speed_down_ && speed > 0)
                    speed_next = speed - 1;
            end
            Count: begin
                // state
                if (rst)
                    state_next = Reset;
                else if (en_)
                    state_next = Pause;
                else
                    state_next = Count;
                // speed
                if (speed_up_ && speed < 2)
                    speed_next = speed + 1;
                else if (speed_down_ && speed > 0)
                    speed_next = speed - 1;
                // cnt
                if (dir_ == 0 && cnt < 99)
                    cnt_next = cnt + 1;
                else if (dir_ == 1 && cnt > 0)
                    cnt_next = cnt - 1;
            end
        endcase
    end

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
            // arrows
            4'd14: DISPLAY = 7'b101_1100;
            4'd15: DISPLAY = 7'b110_0011;
            default: DISPLAY = 7'b111_1111;
        endcase
    end

endmodule