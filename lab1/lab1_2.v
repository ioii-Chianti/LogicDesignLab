`timescale 1ns/100ps

module lab1_1 (
    input wire [3:0] request,
    output reg [3:0] grant
); 
    /* Note that grant can be either reg or wire.
    * e.g.,		output reg [3:0] grant
    * or 		output wire [3:0] grant
    * It depends on how you design your module. */
    // add your design here 
    always @* begin
        if (request[3] == 1'b1)
            grant = 4'b1000;
        else if (request[2] == 1'b1)
            grant = 4'b0100;
        else if (request[1] == 1'b1)
            grant = 4'b0010;
        else if (request[0] == 1'b1)
            grant = 4'b0001;
        else
            grant = 4'b0000;
    end
endmodule

module lab1_2 (
    input wire [5:0] source_0,
    input wire [5:0] source_1,
    input wire [5:0] source_2,
    input wire [5:0] source_3,
    output reg [3:0] result
); 
    /* Note that result can be either reg or wire. 
    * It depends on how you design your module. */
    // add your design here 
    reg [3:0] request;
    wire [3:0] grant;  // error w/ reg
    reg [5:0] source = 6'b000000;

    always @* begin
        request[3] = source_3[5:4] != 0;
        request[2] = source_2[5:4] != 0;
        request[1] = source_1[5:4] != 0;
        request[0] = source_0[5:4] != 0;
    end

    lab1_1 abiter(.request(request), .grant(grant));

    always @*
        case(grant)
            4'b1000: source = source_3;
            4'b0100: source = source_2;
            4'b0010: source = source_1;
            4'b0001: source = source_0;
        endcase
    
    always @*
        case(source[5:4])
            2'b00: result = 4'b0000;
            2'b01: result = source[3:0] & 4'b1010;
            2'b10: result = source[3:0] + 4'd3;
            2'b11: result = source[3:0] << 2;
        endcase

endmodule
