`timescale 1ns/1ps
`define period 10

module uart_transmitter(reset, clk, Tx_DATA, baud_select, Tx_WR, Tx_EN, TxD, Tx_BUSY);
input reset, clk;
input [7:0] Tx_DATA;
input [2:0] baud_select;
input Tx_EN;
input Tx_WR;
output reg TxD; //1bit eksodou apo ta 11 pou stelnei o transmitter ston receiver
output reg Tx_BUSY; //otan == 1 o apostolea stelnei data kai Tx_EN = 1 kai Tx_WR = 0
wire Tx_sample_ENABLE;
reg [3:0] sample_counter = 4'b0000;
integer i=0; //metritis gia thn thesi tou char sto Tx_DATA
reg [2:0] data_counter = 3'b000;
reg [3:0] counter_ones = 4'b0000;
reg start_transm;
reg [2:0] NextState = 3'b000;
reg [2:0] CurrentState = 3'b000;  
reg drive_txd = 1'b0;
reg data_state = 1'b1;
parameter Tx_idle_state = 3'b000;
parameter Tx_start_bit_state = 3'b001;
parameter Tx_data_state = 3'b010;
parameter Tx_parity_bit_state = 3'b011;
parameter Tx_stop_bit_state = 3'b100;

baud_controller baud_controller_tx_inst(.reset(reset), .clk(clk), .baud_select(baud_select), .sample_ENABLE(Tx_sample_ENABLE));

//sequential fsm - allagi katastasis sthn FSM
always@(posedge clk)
begin
    if(reset == 1)
    begin
        CurrentState <= Tx_idle_state;
    end
    else
    begin
        CurrentState <= NextState;
    end
end

//counter gia tin metrhsh 16 Tx_sample_ENABLE
always@(posedge clk)
begin
    if(reset == 1)
    begin
        sample_counter <= 4'b0000;
        data_counter <= 3'b000;
        
    end
    else if(Tx_sample_ENABLE == 1'b1 && Tx_BUSY == 1'b1 && Tx_EN == 1'b1)
    begin
        sample_counter <= sample_counter + 4'b0001;
    end
end

//sima gia oti metrhse 16 Tx_sample_ENABLE
always@(sample_counter)
begin
    if(sample_counter == 4'b1111)
    begin
        drive_txd = 1'b1;
    end
    else
    begin
        drive_txd = 1'b0;
    end
end

//counter gia thn thesi tou bit sto Tx_DATA
always@(data_state)
begin
    if(reset == 1'b1)
    begin
        data_counter = 3'b000;
    end
    else if(data_state == 1'b1)
    begin
        data_counter = data_counter + 3'b001;
    end
    //else gia na min dimiourgeitai latch
    //begin
    //end
end
//combinational fsm
always@(Tx_WR or drive_txd or data_counter)
begin
    case(CurrentState)
            Tx_idle_state:
            begin
                Tx_BUSY = 1'b0;
                if(Tx_WR == 1'b1)
                begin
                    NextState = Tx_start_bit_state;
                    Tx_BUSY = 1'b1;
                    TxD = 1'bx;
                end
                else
                begin
                    NextState = Tx_idle_state;
                    Tx_BUSY = 1'b0;
                    TxD = 1'bx;
                end
            end
            Tx_start_bit_state://stelnei to start bit gia na ksekinisei h metafora dedomenwn
            begin
                TxD = 1'b0;//start bit
                Tx_BUSY = 1'b1;//transmitter is busy
                if(drive_txd == 1)
                begin
                    NextState = Tx_data_state;
                end
                else
                begin
                    NextState = Tx_start_bit_state;
                end
            end
                
            Tx_data_state://stelnei ta data bit pros bit apo to LSB sto MSB
            begin
                data_state = 1'b1;
               
                TxD = Tx_DATA[data_counter];
                Tx_BUSY = 1'b1;//transmitter is busy
    
                if(drive_txd == 1 && data_counter == 3'b111)
                begin
                    data_state = 1'b0;
                    NextState = Tx_parity_bit_state;
                    if(TxD == 1'b1) //counter gia thn katametrhsh twn asswn tou symvolou
                    begin
                        counter_ones = counter_ones + 4'b0001;
                    end
                end
                else if(drive_txd == 1 && data_counter < 3'b111)
                begin
                    data_state = 1'b0;
                    NextState = Tx_data_state; 
                    if(TxD == 1'b1) //counter gia thn katametrhsh twn asswn tou symvolou
                    begin
                       counter_ones = counter_ones + 4'b0001;
                    end
                end
                else
                begin
                    NextState = Tx_data_state; 
                end
            end
    
            Tx_parity_bit_state://stelnei to parity bit
            begin
                Tx_BUSY = 1'b1;//transmitter is busy
                if(counter_ones[0] == 1'b1) //sinthiki gia na doume an to symvolo exei peritto h zygo arithmo asswn
                begin
                    TxD = 1'b1;//parity bit == 1 tote perittos arithmos asswn
                end
                else
                begin
                    TxD = 1'b0;//parity bit == 0 tote zygos arithmos asswn
                end
                 
                if(drive_txd == 1)
                begin
                    NextState = Tx_stop_bit_state;
                end
                else
                begin
                    NextState = Tx_parity_bit_state;
                end
            end
    
            Tx_stop_bit_state://stelnei to stop bit kai deixnei tin liksi tis metaforaw dedwmenwn
            begin
                TxD = 1'b1;//stop bit
                Tx_BUSY = 1'b1;//transmitter is busy
                   
                if(drive_txd == 1)
                begin
                    
                    counter_ones = 4'b0000;
                    NextState = Tx_idle_state;
                end
                else
                begin
                    NextState = Tx_stop_bit_state;
                end
            end
            default:
            begin
                TxD = 1'bx;
                NextState = Tx_idle_state; 
            end
        endcase
end

endmodule
