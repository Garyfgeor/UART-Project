`timescale 1ns/1ps
`define period 10
module uart_receiver_tb();
    reg rst, clk, rx_en, rxd;
    reg [2:0] baud_sel;
    wire [7:0] rx_data;
    wire rx_ferror, rx_perror, rx_valid;
    reg [10:0] message;
    reg [9:0] counter = 10'b0000000000;
    reg new_mes = 1'b0;
    wire Tx_sample_enable;
    reg send_data = 3'b000;
    reg [2:0] next_baud;
    reg [31:0] baud_counter = 32'b00000000000000000000000000000000;

    //kwdikopoihsi twn simvolwn me 11b'1PBxxxxxxxx0 opou x=bit symvolou kai PB=ParityBit apo to MSB --> LSB 
    parameter message_AA = 11'b10101010100; //11'b10010101010;
    parameter message_55 = 11'b10010101010;//11'b10101010100;
    parameter message_CC = 11'b10110011000;//11'b10001100110;
    parameter message_89 = 11'b11100010010;//11'b11100100010;
    
    parameter baud_zero = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
    parameter baud_one = 32'b0000_0000_1101_1111_1101_0000_0100_0000;
    parameter baud_two = 32'b0000_0001_0001_0111_1100_0111_1100_0001;
    parameter baud_three = 32'b0000_0001_0010_0101_1100_1001_1100_0001;
    parameter baud_four = 32'b0000_0001_0010_1100_1100_1101_1000_0010;
    parameter baud_five = 32'b0000_0001_0011_0000_0101_0000_1100_0010;
    parameter baud_six = 32'b0000_0001_0011_0010_0001_0011_1100_0011;
    parameter baud_seven = 32'b0000_0001_0011_0011_0100_0010_0100_0011;
    parameter end_baud = 32'b0000_0001_0011_0011_1101_1100_0100_0100;
    
    uart_receiver uart_receiver_inst(.reset(rst), .clk(clk), .baud_select(baud_sel), .Rx_EN(rx_en), .RxD(rxd),  .Rx_DATA(rx_data), .Rx_FERROR(rx_ferror), .Rx_PERROR(rx_perror), .Rx_VALID(rx_valid));
    baud_controller baud_controller_rx_inst(.reset(rst), .clk(clk), .baud_select(baud_sel), .sample_ENABLE(Tx_sample_enable));

    initial
    begin
        clk = 1'b0;
        rst = 1'b1;
        #10 rst = 1'b0;
    
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
        else
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
    
    //counter gia tin apostoli tou epomenou symvolou
    always@(posedge clk)
    begin
        if(rst == 1'b1 || counter == 10'b1011000000)
        begin
            counter <= 10'b0000000000;
            rx_en <= 1'b0;
        end
        else if(Tx_sample_enable == 1'b1 && rx_en == 1'b1)
        begin
            counter <= counter + 10'b0000000001;
        end
    end
    
    always@(baud_sel)
    begin
        counter = 10'b0000000000;
    end
    
    //analoga me tin timi tou counter stelnetai to antistoixo symvolos
    always@(counter)
    begin
        case(counter)
            10'b00_0000_0000: begin //0 kykloi
                            message = message_AA;
                            new_mes = 1'b1;
                            end
            10'b00_1011_0000: begin// 16*11 = 176 kykloi
                            message = message_55;
                            new_mes = 1'b1;
                            end
            10'b01_0110_0000: begin// 2*16*11 = 352 kykloi
                            message = message_CC;
                            new_mes = 1'b1;
                            end
            10'b10_0001_0000: begin// 3*16*11 = 528 kykloi
                            message = message_89;
                            new_mes = 1'b1;
                            end
            default: new_mes = 1'b0;
        endcase
    end
    
    
    always@(counter)
    begin
        if(new_mes == 1'b0)
        begin
            if(counter % 8'b00010000 == 0)// kano modulo 16 wste an to ypoloipo einai 0, o counter einai pollaplasio tou 16 kai kano right shift to minima
            begin
                //ylopoiisi shifter poy metaferei to bit symvolou sto rxd
                message = message >> 1;
                rxd = message[0];
            end
        end
        else
        begin
            rxd = message[0];
        end
    end
    //dimiourgia rologiou
    always
    begin
       #(`period/2)clk = ~clk;
    end
   
endmodule