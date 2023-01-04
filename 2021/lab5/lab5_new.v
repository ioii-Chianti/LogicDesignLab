module lab5 (
    input clk,
    input rst,
    input BTNL,
    input BTNR,
    input BTNU,
    input BTND,
    input BTNC,
    output reg [15:0] LED,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY
);
    // states
    parameter [3:0] RESET = 4'b0110;
    parameter [3:0] IDLE = 4'b0000;
    parameter [3:0] TYPE = 4'b0001;
    parameter [3:0] AMOUNT = 4'b0010;
    parameter [3:0] PAYMENT = 4'b0011;
    parameter [3:0] RELEASE = 4'b0100;
    parameter [3:0] CHANGE = 4'b0101;
    // ticket type w/ price
    parameter [3:0] child = 4'd5;
    parameter [3:0] student = 4'd10;
    parameter [3:0] adult = 4'd15;
    // next signals
    reg [3:0] state, state_next;
    reg [15:0] led_next;
    reg [3:0] type, type_next;        // IDLE, TYPE
    reg [1:0] amount, amount_next;    // AMOUNT
    reg [5:0] price, price_next;      // AMOUNT
    reg [5:0] money, money_next;      // PAYMENT
    reg [5:0] change, change_next;    // PAYMENT, CHANGE
    reg [3:0] cnt;
    // 7-segment
    reg [3:0] display, digit_0, digit_1, digit_2, digit_3;
    reg [3:0] digit_0_next, digit_1_next, digit_2_next, digit_3_next;

    // clocks
    wire clk_14, clk_25;
    clock_divider #(14) cd1(.clk(clk), .clk_div(clk_14));  // clk for 7-segment
    clock_divider #(25) cd2(.clk(clk), .clk_div(clk_25));  // clk for one second

    // preprocess pushbuttons
    wire db_BTNL, db_BTNR, db_BTNU, db_BTND, db_BTNC;
    wire BTNL_, BTNR_, BTNU_, BTND_, BTNC_;
    debounce d1(.pb_debounced(db_BTNL), .pb(BTNL), .clk(clk_14));
    onepulse o1(.pb_debounced(db_BTNL), .pb_1pulse(BTNL_), .clk(clk_14));
    debounce d2(.pb_debounced(db_BTNR), .pb(BTNR), .clk(clk_14));
    onepulse o2(.pb_debounced(db_BTNR), .pb_1pulse(BTNR_), .clk(clk_14));
    debounce d3(.pb_debounced(db_BTNU), .pb(BTNU), .clk(clk_14));
    onepulse o3(.pb_debounced(db_BTNU), .pb_1pulse(BTNU_), .clk(clk_14));
    debounce d4(.pb_debounced(db_BTND), .pb(BTND), .clk(clk_14));
    onepulse o4(.pb_debounced(db_BTND), .pb_1pulse(BTND_), .clk(clk_14));
    debounce d5(.pb_debounced(db_BTNC), .pb(BTNC), .clk(clk_14));
    onepulse o5(.pb_debounced(db_BTNC), .pb_1pulse(BTNC_), .clk(clk_14));

    always @(posedge clk_14, posedge rst) begin
        if (rst) begin
            state <= RESET;
            type <= child;
            amount <= 1;
            price <= 0;
            money <= 0;
        end else begin
            state <= state_next;
            type <= type_next;
            amount <= amount_next;
            price <= price_next;
            money <= money_next;
        end
    end

    always @(posedge clk_25) begin
        LED <= led_next;
        digit_0 <= digit_0_next;
        digit_1 <= digit_1_next;
        digit_2 <= digit_2_next;
        digit_3 <= digit_3_next;
        change <= change_next;
        cnt <= (state == RELEASE) ? cnt + 1 : 0;
    end

    // state, LED, digit
    always @* begin
        case (state)
            RESET: begin
                state_next = rst ? RESET : IDLE;
                led_next = {16{1'b0}};
                digit_0_next = 4'd15;
                digit_1_next = 4'd15;
                digit_2_next = 4'd15;
                digit_3_next = 4'd15;
            end
            IDLE: begin
                state_next = IDLE;
                led_next = ~LED;
                amount_next = 1;
                price_next = 0;
                money_next = 0;
                // change_next = 0;
                digit_0_next = (digit_0 == 4'd14) ? 4'd15 : 4'd14;
                digit_1_next = (digit_1 == 4'd14) ? 4'd15 : 4'd14;
                digit_2_next = (digit_2 == 4'd14) ? 4'd15 : 4'd14;
                digit_3_next = (digit_3 == 4'd14) ? 4'd15 : 4'd14;
                if (BTNL_) begin
                    state_next = TYPE;
                    type_next = child;
                end else if (BTNC_) begin
                    state_next = TYPE;
                    type_next = student;
                end else if (BTNR_) begin
                    state_next = TYPE;
                    type_next = adult;
                end
            end
            TYPE: begin
                state_next = TYPE;
                led_next = {16{1'b0}};
                type_next = type;
                // price_next = 0;

                if (type == child) begin
                    digit_3_next = 4'd12;
                    digit_2_next = 4'd15;
                    digit_1_next = 4'd15;
                    digit_0_next = 4'd5;
                end else if (type == student) begin
                    digit_3_next = 4'd11;
                    digit_2_next = 4'd15;
                    digit_1_next = 4'd1;
                    digit_0_next = 4'd0;
                end else if (type == adult) begin
                    digit_3_next = 4'd10;
                    digit_2_next = 4'd15;
                    digit_1_next = 4'd1;
                    digit_0_next = 4'd5;
                end

                if (BTNU_)
                    state_next = AMOUNT;
                else if (BTND_)
                    state_next = IDLE;
                else if (BTNL_)
                    type_next = child;
                else if (BTNC_)
                    type_next = student;
                else if (BTNR_)
                    type_next = adult;
            end
            AMOUNT: begin
                state_next = AMOUNT;
                led_next = {16{1'b0}};
                // amount_next = amount;

                if (type == child) begin
                    digit_3_next = 4'd12;
                    digit_2_next = 4'd15;
                    digit_1_next = 4'd15;
                    digit_0_next = amount;
                end else if (type == student) begin
                    digit_3_next = 4'd11;
                    digit_2_next = 4'd15;
                    digit_1_next = 4'd15;
                    digit_0_next = amount;
                end else if (type == adult) begin
                    digit_3_next = 4'd10;
                    digit_2_next = 4'd15;
                    digit_1_next = 4'd15;
                    digit_0_next = amount;
                end

                if (BTNU_) begin
                    state_next = PAYMENT;
                    price_next = amount * type;
                end else if (BTND_) begin
                    state_next = IDLE;
                    // amount_next = 1;
                end else if (BTNL_ && amount > 1) begin
                    amount_next = amount - 1;
                end else if (BTNR_ && amount < 3) begin
                    amount_next = amount + 1;
                end
            end
            PAYMENT: begin
                state_next = PAYMENT;
                led_next = {16{1'b0}};
                // money_next = money;
                digit_3_next = money / 10;
                digit_2_next = money % 10;
                digit_1_next = price / 10;
                digit_0_next = price % 10;

                if (money >= price) begin
                    state_next = RELEASE;
                    change_next = money - price;
                end
                if (BTND_) begin
                    state_next = CHANGE;
                    change_next = money;
                end else if (BTNL_)
                    money_next = money + 1;
                else if (BTNC_)
                    money_next = money + 5;
                else if (BTNR_)
                    money_next = money + 10;
            end
            RELEASE: begin
                state_next = RELEASE;
                led_next = ~LED;
                if (type == child) begin
                    digit_3_next = 4'd12;
                    digit_2_next = 4'd15;
                    digit_1_next = 4'd15;
                    digit_0_next = amount;
                end else if (type == student) begin
                    digit_3_next = 4'd11;
                    digit_2_next = 4'd15;
                    digit_1_next = 4'd15;
                    digit_0_next = amount;
                end else if (type == adult) begin
                    digit_3_next = 4'd10;
                    digit_2_next = 4'd15;
                    digit_1_next = 4'd15;
                    digit_0_next = amount;
                end
                // count to 5 sec
                if (cnt >= 10) begin
                    state_next = CHANGE;
                end
            end
            CHANGE: begin
                state_next = CHANGE;
                // change_next = change;
                led_next = {16{1'b0}};
                digit_3_next = 4'd15;
                digit_2_next = 4'd15;
                digit_1_next = change / 10;
                digit_0_next = change % 10;

                if (change <= 0) begin
                    state_next = IDLE;
                    change_next = 0;
                end else begin
                    state_next = CHANGE;
                    change_next = (change >= 5) ? change - 5 : change - 1;
                end
            end
        endcase
    end
    
    // 7 segment
    always @(posedge clk_14) begin
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
            4'd10: DISPLAY = 7'b000_1000;   // A
            4'd11: DISPLAY = 7'b001_0010;   // S
            4'd12: DISPLAY = 7'b100_0110;   // C
            4'd14: DISPLAY = 7'b011_1111;   // dash
            4'd15: DISPLAY = 7'b111_1111;   // empty
            default: DISPLAY = 7'b111_1111;
        endcase
    end

endmodule