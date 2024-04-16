`timescale 1ns/1ps
`define period 10

module baud_controller_tb;
reg clk, rst;
reg [2:0] baud_sel;
wire sample_EN;

baud_controller baud_controller_inst(.reset(rst), .clk(clk), .baud_select(baud_sel), .sample_ENABLE(sample_EN));
//to baud_rate allazei analoga me to baud sel pou dinoume
initial 
begin
rst = 1'b0;
clk = 1'b0;

baud_sel = 3'b000;
//baud_sel = 3'b001;
//baud_sel = 3'b010;
//baud_sel = 3'b011;
//baud_sel = 3'b100;
//baud_sel = 3'b101;
//baud_sel = 3'b110;
//baud_sel = 3'b111;

end

always
begin
   #(`period/2)clk = ~clk;
end

endmodule