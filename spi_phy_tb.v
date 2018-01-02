`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.06.2017 21:59:47
// Design Name: 
// Module Name: spi_phy_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_phy_tb;

    reg clk, enable, reset;
    reg [7:0] byte_in;
    wire byte_written, byte_valid, clk_out, cs, mosi, miso;
    wire [7:0] byte_out;
           /*
    spi_phy #(
        .N_slaves(2),
        .F_clk_in(100),
        .F_clk_out(50)
        )
    spi_dut
    (
        .clk_in(clk),
        .enable(enable),
        .reset(reset),
        .byte_in(byte_in),
        .byte_written(byte_written),
        .byte_out(byte_out),
        .byte_valid(byte_valid),
        .clk_out(clk_out),
        .cs(cs),
        .mosi(mosi),
        .miso(miso)
    );*/
    
    initial begin
        clk = 0;
        enable = 0;
        reset = 1;
    end
    
    always begin
        #5 clk = !clk;
    end
    
    initial begin
        #0 byte_in = 8'b01010101;
        #20 reset = 0;
        #20 enable = 1; ;
        #2000 enable = 0;
    end
    
    always begin 
        @(posedge byte_written);
        byte_in = ~byte_in;//$random;
    end
    
endmodule
