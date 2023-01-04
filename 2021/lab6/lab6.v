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

module lab06 (
    input clk,
    input rst,
    inout PS2_CLK,
    inout PS2_DATA,
    output [3:0] DIGIT,
    output [6:0] DISPLAY,
    output [15:0] LED
    );

    parameter [2:0] G1 = 3'b000;
    parameter [2:0] G2 = 3'b001;
    parameter [2:0] G3 = 3'b010;
    parameter [2:0] Up = 3'b011;
    parameter [2:0] Down = 3'b100;
    parameter [8:0] one_code = 9'b0_0110_1001;
    parameter [8:0] two_code = 9'b0_0111_0010;
    
    reg [2:0] state, state_next;   // 停在哪個站或上山或下山
    reg [6:0] route, route_next;   // 公車的位置
    reg [6:0] revenue, revenue_next;
    reg [4:0] gas, gas_next;
    reg [2:0] on_bus, on_bus_next, at_B1, at_B1_next, at_B2, at_B2_next;
    wire [2:0] direction;

    wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;

    KeyboardDecoder kd (
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(key_valid),
        .PS2_CLK(PS2_CLK),
        .PS2_DATA(PS2_DATA),
        .rst(rst),
        .clk(clk)
    );

    wire clk_10, clk_26;
    clock_divider #(10) cd1 (.clk(clk), .clk_div(clk_10));
    clock_divider #(26) cd2 (.clk(clk), .clk_div(clk_26));

    assign LED = {at_B1, 1'b0, at_B2, on_bus, 2'b00, route};

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= G1;
        end else begin
            state <= state_next;
        end
    end

    always @(posedge clk_26, posedge rst) begin
        if (rst) begin
            route <= 7'b0000001;
            revenue <= 0;
            gas <= 0;
            on_bus <= 2'b00;
            at_B1 <= 2'b00;
            at_B2 <= 2'b00;
        end else begin
            route <= route_next;
            revenue <= revenue_next;
            gas <= gas_next;
            on_bus <= on_bus_next;
            at_B1 <= at_B1_next;
            at_B2 <= at_B2_next;
        end
    end

    assign direction = (state == Up || state == Down) ? state : direction;

    always @* begin
        case (state)
            G1: begin
                case ({at_B1, on_bus})  // 只會改到B1和on bus
                    // 沒人在車上也沒人在等
                    4'b0000: begin
                        state_next = G1;
                        route_next = 7'b0000001;
                        revenue_next = revenue;
                        gas_next = gas;
                        on_bus_next = 2'b00;
                        at_B1_next = 2'b00;
                        at_B2_next = at_B2;
                    end
                    // 有一個人在等 先收錢讓他上車
                    4'b1000: begin
                        state_next = G1;
                        route_next = 7'b0000001;
                        revenue_next = revenue + 30;
                        gas_next = gas;
                        on_bus_next = 2'b10;
                        at_B1_next = 2'b00;
                        at_B2_next = at_B2;
                    end
                    4'b1100: begin
                        state_next = G1;
                        route_next = 7'b0000001;
                        revenue_next = revenue + 60;
                        gas_next = gas;
                        on_bus_next = 2'b11;
                        at_B1_next = 2'b00;
                        at_B2_next = at_B2;
                    end
                    (4'b0010 || 4'b0011): begin
                        // 油沒滿 有錢可以加
                        if (gas < 20 && revenue >= 10) begin
                            state_next = G1;
                            route_next = 7'b0000001;
                            revenue_next = revenue - 10;
                            gas_next = (gas + 10 <= 20) ? (gas + 10) : 20;
                            on_bus_next = on_bus;
                            at_B1_next = 2'b00;
                            at_B2_next = at_B2;
                        end else begin   // 油滿了 或沒錢可以加 可以上山ㄌ
                            state_next = Up;
                            route_next = route << 1;
                            revenue_next = revenue;
                            gas_next = gas;
                            on_bus_next = on_bus;
                            at_B1_next = at_B1;
                            at_B2_next = at_B2;
                        end
                    end
                endcase
            end
            G2: begin
                if (gas < 20 && revenue >= 10) begin
                    state_next = G2;
                    route_next = 7'b0001000;
                    revenue_next = revenue - 10;
                    gas_next = (gas + 10 <= 20) ? (gas + 10) : 20;
                    on_bus_next = on_bus;
                    at_B1_next = 2'b00;
                    at_B2_next = at_B2;
                end else begin   // 油滿了 或沒錢可以加 可以繼續走
                    state_next = direction;
                    route_next = (direction == Up) ? route << 1 : route >> 1;
                    revenue_next = revenue;
                    gas_next = gas;
                    on_bus_next = on_bus;
                    at_B1_next = at_B1;
                    at_B2_next = at_B2;
                end
            end
            G3: begin
                case ({at_B2, on_bus})  // 只會改到B1和on bus
                    // 沒人在車上也沒人在等
                    4'b0000: begin
                        state_next = G3;
                        route_next = 7'b1000000;
                        revenue_next = revenue;
                        gas_next = gas;
                        on_bus_next = 2'b00;
                        at_B1_next = at_B1;
                        at_B2_next = 2'b00;
                    end
                    // 有一個人在等 先收錢讓他上車
                    4'b1000: begin
                        state_next = G3;
                        route_next = 7'b1000000;
                        revenue_next = revenue + 20;
                        gas_next = gas;
                        on_bus_next = 2'b10;
                        at_B1_next = at_B1;
                        at_B2_next = 2'b00;
                    end
                    4'b1100: begin
                        state_next = G3;
                        route_next = 7'b1000000;
                        revenue_next = revenue + 40;
                        gas_next = gas;
                        on_bus_next = 2'b11;
                        at_B1_next = at_B1;
                        at_B2_next = 2'b00;
                    end
                    (4'b0010 || 4'b0011): begin
                        // 油沒滿 有錢可以加
                        if (gas < 20 && revenue >= 10) begin
                            state_next = G3;
                            route_next = 7'b1000000;
                            revenue_next = revenue - 10;
                            gas_next = (gas + 10 <= 20) ? (gas + 10) : 20;
                            on_bus_next = on_bus;
                            at_B1_next = at_B1;
                            at_B2_next = 2'b00;
                        end else begin   // 油滿了 或沒錢可以加 可以上山ㄌ
                            state_next = Down;
                            route_next = route >> 1;
                            revenue_next = revenue;
                            gas_next = gas;
                            on_bus_next = on_bus;
                            at_B1_next = at_B1;
                            at_B2_next = at_B2;
                        end
                    end
                endcase
            end
            Up: begin
                if (route == 7'b0001000) begin
                    state_next = G2;
                    route_next = 7'b0001000;
                    revenue_next = revenue;
                    if (on_bus == 2'b10)
                        gas_next = gas - 5;
                    else if (on_bus == 2'b11)
                        gas_next = gas - 10;
                    on_bus_next = on_bus;
                    at_B1_next = at_B1;
                    at_B2_next = at_B2;
                end else if (route == 7'b1000000) begin
                    state_next = G3;
                    route_next = 7'b1000000;
                    revenue_next = revenue;
                    if (on_bus == 2'b10)
                        gas_next = gas - 5;
                    else if (on_bus == 2'b11)
                        gas_next = gas - 10;
                    on_bus_next = on_bus;
                    at_B1_next = at_B1;
                    at_B2_next = at_B2;
                end else begin
                    state_next = Up;
                    route_next = route << 1;
                    revenue_next = revenue;
                    gas_next = gas;
                    on_bus_next = on_bus;
                    at_B1_next = at_B1;
                    at_B2_next = at_B2;
                end
            end
            Down: begin
                if (route == 7'b0001000) begin
                    state_next = G2;
                    route_next = 7'b0001000;
                    revenue_next = revenue;
                    if (on_bus == 2'b10)
                        gas_next = gas - 5;
                    else if (on_bus == 2'b11)
                        gas_next = gas - 10;
                    on_bus_next = on_bus;
                    at_B1_next = at_B1;
                    at_B2_next = at_B2;
                end else if (route == 7'b0000001) begin
                    state_next = G1;
                    route_next = 7'b0000001;
                    revenue_next = revenue;
                    if (on_bus == 2'b10)
                        gas_next = gas - 5;
                    else if (on_bus == 2'b11)
                        gas_next = gas - 10;
                    on_bus_next = on_bus;
                    at_B1_next = at_B1;
                    at_B2_next = at_B2;
                end else begin
                    state_next = Down;
                    route_next = route >> 1;
                    revenue_next = revenue;
                    gas_next = gas;
                    on_bus_next = on_bus;
                    at_B1_next = at_B1;
                    at_B2_next = at_B2;
                end
            end
        endcase
    end

    always @* begin
        // line 448
    end

endmodule