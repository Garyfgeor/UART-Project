`timescale 1ns/1ps
`define period 10

module uart_transmitter_tb;
reg rst, clk, Tx_wr, Tx_en;
reg [7:0] Tx_data;
reg [2:0] baud_sel;
wire Tx_D;
wire Tx_busy;
reg [2:0] symbol;
reg [31:0] baud_counter = 32'b00000000000000000000000000000000;

parameter char_AA = 8'b10101010;
parameter char_55 = 8'b01010101;
parameter char_CC = 8'b11001100;
parameter char_89 = 8'b10001001;

parameter s_AA = 3'b000;
parameter s_55 = 3'b001;
parameter s_CC = 3'b010;
parameter s_89 = 3'b011;

parameter baud_zero = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
parameter baud_one = 32'b0000_0000_1101_1111_1101_0000_0100_0000;
parameter baud_two = 32'b0000_0001_0001_0111_1100_0111_1100_0001;
parameter baud_three = 32'b0000_0001_0010_0101_1100_1001_1100_0001;
parameter baud_four = 32'b0000_0001_0010_1100_1100_1101_1000_0010;
parameter baud_five = 32'b0000_0001_0011_0000_0101_0000_1100_0010;
parameter baud_six = 32'b0000_0001_0011_0010_0001_0011_1100_0011;
parameter baud_seven = 32'b0000_0001_0011_0011_0100_0010_0100_0011;
parameter end_baud = 32'b0000_0001_0011_0011_1101_1100_0100_0100;

uart_transmitter uart_transmitter_inst(.reset(rst), .clk(clk), .Tx_DATA(Tx_data), .baud_select(baud_sel), .Tx_WR(Tx_wr), .Tx_EN(Tx_en), .TxD(Tx_D), .Tx_BUSY(Tx_busy));

initial
begin
    clk = 1'b0;
    rst = 1'b1;
    #30 rst = 1'b0;
    Tx_en = 1'b1;
    baud_sel = 3'b000;
   
    symbol = 3'b000;
    Tx_wr = 1'b0;
end

always@(posedge clk)
begin
    if(Tx_en == 1'b1 && Tx_busy == 1'b0)
    begin
        //metafora tou symvoloy pros apostoli ston transmitter apo to testbench
        case(symbol)
            s_AA: Tx_data <= char_AA;
            s_55: Tx_data <= char_55;
            s_CC: Tx_data <= char_CC;
            s_89: Tx_data <= char_89;
            default: Tx_data <= 8'b00000000;
        endcase
        
        //enallagi symvolwn
        if(symbol == s_89 && baud_sel == 3'b111)
        begin
            symbol <= 3'b100;
        end
        else if(symbol == s_89 && baud_sel < 3'b111)
        begin
            symbol <= 3'b000;
        end
        else
        begin    
            symbol <= symbol + 3'b001;
        end
        Tx_wr <= 1'b1;
        #(`period)Tx_wr <= 1'b0;    
    end
    else if(Tx_busy == 1'b1)
    begin
        Tx_en <= 1'b1;
    end
end

//counter gia tin enallagi twn baud rate
always@(posedge clk)
begin
    if(rst == 1'b1 || baud_counter == 32'b0000_0001_0011_0011_1101_1100_0100_0100)
    begin
        baud_counter <= 32'b00000000000000000000000000000000;
    end
    else if(Tx_en == 1'b1)
    begin
        baud_counter <= baud_counter + 32'b00000000000000000000000000000001;
    end
end

//analoga tin timi tou counter h epikoinonia ginetai me allo baud rate
always@(baud_counter)
begin
    case(baud_counter)
    baud_one:
        begin 
            baud_sel = 3'b001;
        end
    baud_two:
        begin 
            baud_sel = 3'b010;
        end
    baud_three:
        begin 
            baud_sel = 3'b011;
        end
    baud_four:
        begin 
            baud_sel = 3'b100;
        end
    baud_five:
        begin 
            baud_sel = 3'b101;
        end
    baud_six:
        begin 
            baud_sel = 3'b110;
        end
    baud_seven:
        begin 
            baud_sel = 3'b111;
        end
    end_baud:
        begin
            baud_sel = 3'bxxx;
        end
   default: Tx_en = 1'b1;
       
    endcase
end

//dimiourgia rologiou
always
begin
   #(`period/2)clk = ~clk;
end

endmodule