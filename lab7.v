module clock_divider(clk_1, clk, clk_22);
    input clk;
    output clk_1;
    output clk_22;

    reg [21:0] num;
    wire [21:0] next_num;

    always @(posedge clk)
        num <= next_num;

    assign next_num = num + 1'b1;
    assign clk_1 = num[1];
    assign clk_22 = num[21];
endmodule


module lab7_1(
    input clk,
    input rst,
    input en,
    input dir,
    input vmir,
    input hmir,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
);
    wire [16:0] pixel_addr;
    wire [11:0] pixel, data;
    wire [9:0] h_cnt, v_cnt;   // 640 * 480
    wire clk_1, clk_22, valid;
    clock_divider c(.clk(clk), .clk_1(clk_1), .clk_22(clk_22));

    assign {vgaRed, vgaGreen, vgaBlue} = valid ? pixel : 0;

    mem_addr_gen m(
        .clk(clk_22),
        .rst(rst),
        .en(en),
        .dir(dir),
        .vmir(vmir),
        .hmir(hmir),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr)
    );

    blk_mem_gen_0 b(
        .clka(clk_1),
        .wea(0),
        .addra(pixel_addr),
        .dina(data[11:0]),
        .douta(pixel)
    );

    vga_controller v(
        .pclk(clk_1),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    ); 
endmodule


module mem_addr_gen(
    input clk,
    input rst,
    input en,
    input dir,
    input vmir,
    input hmir,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output reg [16:0] pixel_addr
    );

    reg [7:0] position;

    always @* begin
        if (vmir && hmir)
            pixel_addr = (((640-h_cnt)>>1) + 320*((480-v_cnt)>>1) + position*320) % 76800;
        else if (vmir)
            pixel_addr = ((h_cnt>>1) + 320*((480-v_cnt)>>1) + position*320) % 76800;
        else if (hmir)
            pixel_addr = (((640-h_cnt)>>1) + 320*(v_cnt>>1) + position*320) % 76800;
        else
            pixel_addr = ((h_cnt>>1) + 320*(v_cnt>>1) + position*320) % 76800;
    end

    // assign pixel_addr = ((h_cnt>>1) + 320*(v_cnt>>1) + position*320) % 76800;  //640*480 --> 320*240 

    always @ (posedge clk or posedge rst) begin
        if (rst)
            position <= 0;
        else if (en) begin
            if (!dir)
                position <= (position < 239) ? position + 1 : 0;
            else
                position <= (position > 0) ? position - 1 : 239;
        end
    end
endmodule