module clock_sec (
    input clk,
    input rst,
    output reg clk_1sec
);
    reg [26:0] cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            clk_1sec <= 0;
        end else if (cnt == 27'd5000_0000) begin 
            cnt <= 0;
            clk_1sec <= ~clk_1sec;
        end else begin
            cnt <= cnt + 1;    
        end 
    end
endmodule


module LFSR (
    input clk,
    input rst,
    input [8:0] seed,
    output reg [8:0] random
);
    wire tmp = ~(seed[3] ^ seed[2]);
    always @(posedge clk or posedge rst) begin
        if (rst)
            random <= seed ? seed : 9'b101101001;
        else
            random <= {seed[7:0], tmp};
    end
endmodule


module lab6 (
    input wire clk,
    input wire rst,
    input wire start,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    output reg [15:0] LED,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY
);

    // clocks
    wire clk_7segment, clk_1sec;
    clock_divider #(.n(14)) cd0(.clk(clk), .clk_div(clk_7segment));
    clock_sec sc(.clk(clk), .rst(rst), .clk_1sec(clk_1sec));

    // preprocess pushbuttons
    wire db_rst, _rst;
    debounce d0(.pb_debounced(db_rst), .clk(clk), .pb(rst));
    OnePulse o0(.signal(db_rst), .clock(clk_7segment), .signal_single_pulse(_rst));
    wire db_start, _start;
    debounce d2(.pb_debounced(db_start), .clk(clk), .pb(start));
    OnePulse o2(.signal(db_start), .clock(clk_7segment), .signal_single_pulse(_start));

    // states and signals
    parameter Init = 2'd0;
    parameter Game = 2'd1;
    parameter Final = 2'd2;
    parameter Reset = 2'd3;
    reg [1:0] state, state_next;
    reg [4:0] count, score, score_next;

    // random mole
    reg [8:0] mole = 9'b101101001, mole_next;
    wire [8:0] random;
    LFSR l(.clk(clk_1sec), .rst(_rst), .seed(mole), .random(random));

    // keyboard signals
    reg [3:0] key_num;   // trans keycode (last_change) to corresponding decimal
    wire [511:0] key_down;
	wire [8:0] last_change;   // last pressing keycode
	wire been_ready;

    parameter [8:0] key_code [0:9] = {
        9'b0_0100_0101,   // 0 -> 45
		9'b0_0001_0110,   // 1 -> 16
		9'b0_0001_1110,   // 2 -> 1E
		9'b0_0010_0110,   // 3 -> 26
		9'b0_0010_0101,   // 4 -> 25
		9'b0_0010_1110,   // 5 -> 2E
		9'b0_0011_0110,   // 6 -> 36
		9'b0_0011_1101,   // 7 -> 3D
		9'b0_0011_1110,   // 8 -> 3E
		9'b0_0100_0110    // 9 -> 46
    };

    KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);

    always @* begin
        case (last_change)
            key_code[01]: key_num = 4'd1;
            key_code[02]: key_num = 4'd2;
            key_code[03]: key_num = 4'd3;
            key_code[04]: key_num = 4'd4;
            key_code[05]: key_num = 4'd5;
            key_code[06]: key_num = 4'd6;
            key_code[07]: key_num = 4'd7;
            key_code[08]: key_num = 4'd8;
            key_code[09]: key_num = 4'd9;
            default     : key_num = 4'b1111;
        endcase
    end

    // update state
    always @* begin
        case (state)
            Init: begin
                state_next = _start ? Game : Init;
                score_next = 0;
                mole_next = random;
            end
            Game: begin
                state_next = (count <= 0 || score >= 10) ? Final : Game;
                // score_next = score;
                // mole_next = random; // 不會有影響

                if (been_ready && key_down[last_change] == 1) begin
                    if (key_num != 4'b1111) begin
                        if (mole[key_num - 1] == 1) begin
                            score_next = score + 1;
                            mole_next = mole;
                            mole_next[key_num - 1] = 0;
                        end else begin
                            score_next = score;
                            mole_next = random;
                        end
                    end else begin
                        score_next = score;
                        mole_next = random;
                    end
                end else begin
                    score_next = score;
                    mole_next = random;
                end
            end
            Final: begin
                state_next = _start ? Reset : Final;
                score_next = score;
                mole_next = random;
            end
            Reset: begin
                state_next = Game;
                score_next = 0;
                mole_next = random;
            end
        endcase
    end

    always @(posedge clk or posedge _rst) begin
        if (_rst) begin
            state <= Init;
            score <= 0;
            mole <= 9'b101101001;
        end else begin
            state <= state_next;
            score <= score_next;
            mole <= mole_next;
        end
    end

    // set count
    always @(posedge clk_1sec or posedge _rst) begin
        if (_rst) begin
            count <= 30;
        end else begin
            count <= (state == Game) ? count - 1 : 30;
        end
    end

    always @* begin
        case (state)
            Init: LED = {16{1'b0}};
            Game: begin
                LED[15] = mole[0];
                LED[14] = mole[1];
                LED[13] = mole[2];
                LED[12] = mole[3];
                LED[11] = mole[4];
                LED[10] = mole[5];
                LED[9] = mole[6];
                LED[8] = mole[7];
                LED[7] = mole[8];
                LED[6:0] = 0;
            end
            Final: LED = {16{1'b1}};
        endcase
    end

    // 7. 7-segment
    reg [3:0] display;
    reg [3:0] digit_0, digit_1, digit_2, digit_3;

    always @* begin
        case (state)
            Init: begin
                digit_0 = 10;
                digit_1 = 10;
                digit_2 = 10;
                digit_3 = 10;
            end
            (Game || Reset): begin
                digit_0 = score % 10;
                digit_1 = score / 10;
                digit_2 = count % 10;
                digit_3 = count / 10;
            end
            Final: begin
                if (score >= 10) begin
                    digit_0 = 15;
                    digit_1 = 14;
                    digit_2 = 13;
                    digit_3 = 10;
                end else begin
                    digit_0 = score % 10;
                    digit_1 = score / 10;
                    digit_2 = 0;
                    digit_3 = 0;
                end
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
            // WIN
            4'd13: DISPLAY = 7'b110_0010;
            4'd14: DISPLAY = 7'b100_1111;
            4'd15: DISPLAY = 7'b100_1000;
            default: DISPLAY = 7'b111_1111;
        endcase
    end
    
endmodule