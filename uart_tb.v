module uart_tb();
reg rst, clk, tx_wr, tx_en, rx_en;
reg [7:0] tx_data;
reg [2:0] baud_sel;
wire tx_D, tx_busy, rx_ferror, rx_perror, rx_valid;
wire [7:0] rx_data;
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

uart uart_inst(.reset(rst), .clk(clk), .Tx_wr(tx_wr), .Tx_en(tx_en), .rx_en(rx_en), .Tx_data(tx_data), .baud_sel(baud_sel), .Tx_D(tx_D), .Tx_busy(tx_busy), .rx_ferror(rx_ferror), .rx_perror(rx_perror), .rx_valid(rx_valid), .rx_data(rx_data));

initial
begin
    clk = 1'b0;
    rst = 1'b1;
    #30 rst = 1'b0;
    tx_en = 1'b1;
    symbol = 3'b000;
    tx_wr = 1'b0;
    baud_sel = 3'b000;
    rx_en = 1'b1;
end

//counter kyklwn gia enallagi tou baud sel
always@(posedge clk)
begin
    if(rst == 1'b1 || baud_counter == 32'b0000_0001_0011_0011_1101_1100_0100_0100)
    begin
        baud_counter <= 32'b00000000000000000000000000000000;
    end
    else if(tx_en == 1'b1 && rx_en == 1'b1)
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
            rx_en = 1'b1;
            end
        baud_two:
            begin 
            baud_sel = 3'b010;
            rx_en = 1'b1;
            end
        baud_three:
            begin 
            baud_sel = 3'b011;
            rx_en = 1'b1;
            end
        baud_four:
            begin 
            baud_sel = 3'b100;
            rx_en = 1'b1;
            end
        baud_five:
            begin 
            baud_sel = 3'b101;
            rx_en = 1'b1;
            end
        baud_six:
            begin 
            baud_sel = 3'b110;
            rx_en = 1'b1;
            end
        baud_seven:
            begin 
            baud_sel = 3'b111;
            rx_en = 1'b1;
            end
        end_baud:
            begin
            baud_sel = 3'bxxx;
            rx_en = 1'b0;
            end
        default: rx_en = 1'b1;
    endcase
end

always@(posedge clk)
begin
    if(tx_en == 1'b1 && tx_busy == 1'b0 )
    begin
        //metafora tou symvoloy pros apostoli ston transmitter apo to testbench
        case(symbol)
            s_AA: tx_data <= char_AA;
            s_55: tx_data <= char_55;
            s_CC: tx_data <= char_CC;
            s_89: tx_data <= char_89;
            default: begin
                    tx_data <= 8'b00000000;
                    tx_en <= 1'b0;
                    rx_en <= 1'b0;
                    end
        endcase
        
        tx_wr <= 1'b1;
        #(`period)tx_wr <= 1'b0;
        
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
    end
    else if(tx_busy == 1'b1)
    begin
        tx_en <= 1'b1;
    end
end

//energopoihsh tou receiver
always@(posedge clk)
begin
    if(tx_D == 1'b0)//start bit
    begin
        rx_en = 1'b1;
    end
end

//dimiourgia rologiou
always
begin
   #(`period/2)clk = ~clk;
end
endmodule