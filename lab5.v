module lab5 (
    input wire clk,
    input wire rst,
    input wire BTNR,
    input wire BTNU,
    input wire BTND,
    input wire BTNL,
    output reg [15:0] LED,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY
);

    // 1. preprocess pushbuttons
    wire db_rst, _rst;
    debounce d0(.pb_debounced(db_rst), .clk(clk), .pb(rst));
    one_pulse o0(.pb_in(db_rst), .clk(clk), .pb_out(_rst));
    wire db_BTNR, _BTNR;
    debounce d1(.pb_debounced(db_BTNR), .clk(clk), .pb(BTNR));
    one_pulse o1(.pb_in(db_BTNR), .clk(clk), .pb_out(_BTNR));
    wire db_BTNU, _BTNU;
    debounce d2(.pb_debounced(db_BTNU), .clk(clk), .pb(BTNU));
    one_pulse o2(.pb_in(db_BTNU), .clk(clk), .pb_out(_BTNU));
    wire db_BTND, _BTND;
    debounce d3(.pb_debounced(db_BTND), .clk(clk), .pb(BTND));
    one_pulse o3(.pb_in(db_BTND), .clk(clk), .pb_out(_BTND));
    wire db_BTNL, _BTNL;
    debounce d4(.pb_debounced(db_BTNL), .clk(clk), .pb(BTNL));
    one_pulse o4(.pb_in(db_BTNL), .clk(clk), .pb_out(_BTNL));


    // 2. States and next signals
    parameter Idle = 3'd0;
    parameter Set = 3'd1;
    parameter Guess = 3'd2;
    parameter Check = 3'd5;
    parameter Wrong = 3'd3;
    parameter Correct = 3'd4;
    reg [2:0] state, state_next, cycle;
    reg [2:0] selectedDigit, selectedDigit_next;
    reg [13:0] ans, ans_next, guess, guess_next;
    reg [5:0] count_A, count_A_next, count_B, count_B_next;
    reg [15:0] LED_next;


    // 3. clocks
    wire clk_7segment, clk_led;
    clock_divider #(.n(14)) cd0 (.clk(clk), .clk_div(clk_7segment));
    clock_divider #(.n(27)) cd1 (.clk(clk), .clk_div(clk_27));
    assign clk_led = (state == Correct) ? clk_27 : clk;
    

    // 4. Update signals
    always @(posedge clk_led or posedge _rst) begin
        if (_rst) begin
            state <= Idle;
            selectedDigit <= 3;
            ans <= 0;
            guess <= 0;
            cycle <= 0;
            count_A <= 0;
            count_B <= 0;
        end else begin
            state <= state_next;
            selectedDigit <= selectedDigit_next;
            ans <= ans_next;
            guess <= guess_next;
            cycle <= (state == Correct) ? cycle + 1 : 0;
            count_A <= count_A_next;
            count_B <= count_B_next;
        end
    end


    // 5. Update next signals
    always @* begin
        case (state)
            Idle: begin
                state_next = _BTNR ? Set : Idle;
                selectedDigit_next = 3;
                ans_next = 0;
                guess_next = 0;
                count_A_next = 0;
                count_B_next = 0;
            end

            Set: begin
                state_next = Set;
                selectedDigit_next = selectedDigit;
                ans_next = ans;
                guess_next = 0;
                count_A_next = 0;
                count_B_next = 0;

                if (_BTNL)
                    state_next = Idle;
                else if (_BTNR && selectedDigit == 0) begin
                    state_next = Guess;
                    selectedDigit_next = 3;
                end else if (_BTNR)
                    selectedDigit_next = selectedDigit - 1;

                // configure ans
                if (_BTNU) begin   // +
                    case (selectedDigit)
                        0: ans_next = (ans % 10 == 9) ? ans : ans + 1;
                        1: ans_next = (ans / 10 % 10 == 9) ? ans : ans + 10;
                        2: ans_next = (ans / 100 % 10 == 9) ? ans : ans + 100;
                        3: ans_next = (ans / 1000 % 10 == 9) ? ans : ans + 1000;
                    endcase
                end else if (_BTND) begin   // -
                    case (selectedDigit)
                        0: ans_next = (ans % 10 == 0) ? ans : ans - 1;
                        1: ans_next = (ans / 10 % 10 == 0) ? ans : ans - 10;
                        2: ans_next = (ans / 100 % 10 == 0) ? ans : ans - 100;
                        3: ans_next = (ans / 1000 % 10 == 0) ? ans : ans - 1000;
                    endcase
                end
            end

            Guess: begin
                state_next = Guess;
                selectedDigit_next = selectedDigit;
                ans_next = ans;
                guess_next = guess;
                count_A_next = 0;
                count_B_next = 0;

                if (_BTNL)
                    state_next = Idle;
                else if (_BTNR && selectedDigit == 0) begin
                    state_next = Check;
                    selectedDigit_next = 3;
                end else if (_BTNR)
                    selectedDigit_next = selectedDigit - 1;

                // configure guess
                if (_BTNU) begin   // +
                    case (selectedDigit)
                        0: guess_next = (guess % 10 == 9) ? guess : guess + 1;
                        1: guess_next = (guess / 10 % 10 == 9) ? guess : guess + 10;
                        2: guess_next = (guess / 100 % 10 == 9) ? guess : guess + 100;
                        3: guess_next = (guess / 1000 % 10 == 9) ? guess : guess + 1000;
                    endcase
                end else if (_BTND) begin   // -
                    case (selectedDigit)
                        0: guess_next = (guess % 10 == 0) ? guess : guess - 1;
                        1: guess_next = (guess / 10 % 10 == 0) ? guess : guess - 10;
                        2: guess_next = (guess / 100 % 10 == 0) ? guess : guess - 100;
                        3: guess_next = (guess / 1000 % 10 == 0) ? guess : guess - 1000;
                    endcase
                end
            end

            Check: begin
                state_next = (ans == guess) ? Correct : Wrong;
                selectedDigit_next = 3;
                ans_next = ans;
                guess_next = guess;
                count_A_next = 0;
                count_B_next = 0;

                if (ans % 10 == guess % 10)
                    count_A_next = count_A_next + 1;
                else if ((ans % 10 == guess / 10 % 10) || (ans % 10 == guess / 100 % 10) || (ans % 10 == guess / 1000))
                    count_B_next = count_B_next + 1;
                if (ans / 10 % 10 == guess / 10 % 10)
                    count_A_next = count_A_next + 1;
                else if ((ans / 10 % 10 == guess % 10) || (ans / 10 % 10 == guess / 100 % 10) || (ans / 10 % 10 == guess / 1000))
                    count_B_next = count_B_next + 1;
                if (ans / 100 % 10 == guess / 100 % 10)
                    count_A_next = count_A_next + 1;
                else if ((ans / 100 % 10 == guess % 10) || (ans / 100 % 10 == guess / 10 % 10) || (ans / 100 % 10 == guess / 1000))
                    count_B_next = count_B_next + 1;
                if (ans / 1000 == guess / 1000)
                    count_A_next = count_A_next + 1;
                else if ((ans / 1000 == guess % 10) || (ans / 1000 == guess / 10 % 10) || (ans / 1000 == guess / 100 % 10))
                    count_B_next = count_B_next + 1;
            end

            Wrong: begin
                state_next = Wrong;
                selectedDigit_next = 3;
                ans_next = ans;
                guess_next = 0;
                count_A_next = count_A;
                count_B_next = count_B;

                if (_BTNL)
                    state_next = Idle;
                else if (_BTNR)
                    state_next = Guess;
            end

            Correct: begin
                state_next = (cycle > 4) ? Idle : Correct;
                selectedDigit_next = 3;
                ans_next = 0;
                guess_next = 0;
                count_A_next = 0;
                count_B_next = 0;
            end
        endcase
    end


    // 6. set LED
    always @(posedge clk_led) begin
        case (state)
            Idle: LED <= 16'b1111_0000_0000_0000;
            Set: LED <= LED_next;
            Guess: LED <= LED_next;
            Wrong: LED <= 16'b0000_0000_0000_1111;
            Correct: LED <= LED_next;
        endcase
    end
    
    always @* begin
        case (state)
            Set: begin
                LED_next = {16{1'b0}};
                LED_next[selectedDigit + 8] = 1;
            end
            Guess: begin
                LED_next = {16{1'b0}};
                LED_next[selectedDigit + 4] = 1;
            end
            Correct:
                LED_next = (LED[0] == 0) ? {16{1'b1}} : {16{1'b0}};
        endcase
    end


    // 7. 7-segment
    reg [3:0] display;
    reg [3:0] digit_0, digit_1, digit_2, digit_3;

    always @* begin
        case (state)
            Idle: begin   // ----
                digit_0 = 10;
                digit_1 = 10;
                digit_2 = 10;
                digit_3 = 10;
            end
            Set: begin    // ans 
                digit_0 = ans % 10;
                digit_1 = ans / 10 % 10;
                digit_2 = ans / 100 % 10;
                digit_3 = ans / 1000;
            end
            Guess: begin
                digit_0 = guess % 10;
                digit_1 = guess / 10 % 10;
                digit_2 = guess / 100 % 10;
                digit_3 = guess / 1000;
            end
            Check: begin
                digit_0 = guess % 10;
                digit_1 = guess / 10 % 10;
                digit_2 = guess / 100 % 10;
                digit_3 = guess / 1000;
            end
            Wrong: begin    // ?A?B
                digit_0 = 15;
                digit_1 = count_B;
                digit_2 = 14;
                digit_3 = count_A;
            end
            Correct: begin  // 4A0B
                digit_0 = 15;
                digit_1 = 0;
                digit_2 = 14;
                digit_3 = 4;
            end
        endcase
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
            // AB
            4'd14: DISPLAY = 7'b000_1000;   // A
            4'd15: DISPLAY = 7'b000_0011;   // B
            default: DISPLAY = 7'b111_1111;
        endcase
    end
    
endmodule