`timescale 1ns/1ps
`define period 10
//parexei to sima deigmatolipsias analoga me to baud rate
module baud_controller(reset, clk, baud_select, sample_ENABLE);
input reset, clk; //clk of 100MHz FPGA
input [2:0] baud_select;
output reg sample_ENABLE = 1'b0;
reg [14:0] count = 15'b000000000000000; 
reg [14:0] max_count = 15'bxxxxxxxxxxxxxxx;

parameter baud_zero = 3'b000;
parameter baud_one = 3'b001;
parameter baud_two = 3'b010;
parameter baud_three = 3'b011;
parameter baud_four = 3'b100;
parameter baud_five = 3'b101;
parameter baud_six = 3'b110;
parameter baud_seven = 3'b111;

//o counter tha metraei ta bits analoga me to baud select
always@(baud_select)
begin
    case(baud_select)
    //o counter lamvanei times me vasei to baud_rate apo ton typo 10^8/(16*baud_rate)
    baud_zero: max_count = 15'b101_0001_0110_0010;
    baud_one: max_count = 15'b001_0100_0101_1001;
    baud_two: max_count = 15'b000_0101_0001_0111;
    baud_three: max_count = 15'b000_0010_1000_1100;
    baud_four: max_count = 15'b000_0001_0100_0110;
    baud_five: max_count = 15'b000_0000_1010_0011;
    baud_six: max_count = 15'b000_0000_0110_1101;
    baud_seven: max_count = 15'b000_0000_0011_0111;
    endcase
end

//ylopoihsh counter gia thn katametrhsh kyklwn rologiou analoga me to baud rate
always@(posedge clk)
begin
    if(count == max_count)
    begin
        count <= 15'b000_0000_0000_0000; 
        sample_ENABLE <= 1'b1;
    end
    else
    begin 
        count <= count + 15'b000_0000_0000_0001;
        sample_ENABLE <= 1'b0;
    end
end

endmodule