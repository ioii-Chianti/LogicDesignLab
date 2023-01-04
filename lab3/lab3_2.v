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

module lab3_2
(
    input clk,
    input rst,
    input en,
    input speed,
    input freeze,
    output reg [15:0] led
);

    parameter [2:0] Reset = 3'd1;
    parameter [2:0] Racing = 3'd2;
    parameter [2:0] Mot_Finish = 3'd3;
    parameter [2:0] Car_Finish = 3'd4;
    parameter [2:0] Mot_Win = 3'd5;
    parameter [2:0] Car_Win = 3'd6;

    wire clk_fast, clk_normal;
    reg clk_car;
    clock_divider #(.n(24)) cd0 (clk, clk_fast);
    clock_divider #(.n(27)) cd1 (clk, clk_normal);

    reg [2:0] state, state_next;
    reg [1:0] Mot_score, Mot_score_next, Car_score, Car_score_next;
    reg [3:0] Mot_position, Mot_position_next, Car_position, Car_position_next;
    reg [2:0] speedRound, speedRound_next;
    wire speedFlag = (speedRound < 5);

    always @(posedge clk_normal or posedge rst) begin
        if (rst) begin
            state <= Reset;
            Mot_score <= 0;
            Mot_position <= 10;
        end else if (en) begin
            state <= state_next;
            Mot_score <= Mot_score_next;
            Mot_position <= Mot_position_next;
        end
    end

    always @(speed)
        clk_car = speed ? clk_fast : clk_normal;

    always @(posedge clk_car or posedge rst) begin
        if (rst) begin
            speedRound <= 0;
            Car_score <= 0;
            Car_position <= 12;
        end else if (en) begin
            speedRound <= speedRound_next;
            Car_score <= Car_score_next;
            Car_position <= Car_position_next;
        end
    end

    always @* begin
        if (rst)
            led = 16'b00_1101_0000_0000_00;
        else if (state == Mot_Win)
            led = 16'b0011_1111_1111_1111;
        else if (state == Car_Win)
            led = 16'b1111_1111_1111_1100;
        else begin
            led[13:2] = {12{1'b0}};
            led[Mot_position] = 1;
            led[Car_position] = 1;
            led[Car_position + 1] = 1;
            led[15:14] = Car_score;
            led[1:0] = Mot_score;
        end
    end

    always @* begin
        case (state)
            Reset: begin
                state_next = Racing;
                Mot_score_next = Mot_score;
                Car_score_next = Car_score;
                Mot_position_next = 10;
                Car_position_next = 12;
                speedRound_next = 0;
            end

            Racing: begin
                // count speed's round
                speedRound_next = speed ? speedRound + 1 : speedRound;

                if (Mot_position == 3) begin
                    state_next = Mot_Finish;
                    speedRound_next = 0;
                end else if (Car_position == 3) begin
                    state_next = Car_Finish;
                    speedRound_next = 0;
                end else begin
                    state_next = Racing;
                end
                // score
                Mot_score_next = Mot_score;
                Car_score_next = Car_score;
                // position
                Mot_position_next = freeze ? Mot_position : Mot_position - 1;
                Car_position_next = Car_position - 1;
            end

            Mot_Finish: begin
                if (Mot_score == 3) begin
                    state_next = Mot_Win;
                    Mot_score_next = 0;
                end else begin
                    state_next = Reset;
                    Mot_score_next = Mot_score + 1;
                end
                Mot_position_next = Mot_position;
                Car_position_next = Car_position;

                speedRound_next = 0;
            end
            
            Car_Finish: begin
                if (Car_score == 3) begin
                    state_next = Car_Win;
                    Car_score_next = 0;
                end else begin
                    state_next = Reset;
                    Car_score_next = Car_score + 1;
                end
                Mot_position_next = Mot_position;
                Car_position_next = Car_position;

                speedRound_next = 0;
            end

            Mot_Win: begin
                state_next = Reset;
                Mot_position_next = Mot_position;
                Car_position_next = Car_position;
                Mot_score_next = 0;
                Car_score_next = 0;

                speedRound_next = 0;
            end
            
            Car_Win: begin
                state_next = Reset;
                Mot_position_next = Mot_position;
                Car_position_next = Car_position;
                Mot_score_next = 0;
                Car_score_next = 0;

                speedRound_next = 0;
            end

        endcase
    end

endmodule
