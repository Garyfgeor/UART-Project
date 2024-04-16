module uart_receiver(reset, clk, baud_select, Rx_EN, RxD, Rx_DATA, Rx_FERROR, Rx_PERROR, Rx_VALID);
input reset, clk;
input [2:0] baud_select;
input Rx_EN;
input RxD;
output reg[7:0] Rx_DATA;
reg [7:0] received_data;
output reg Rx_FERROR; // Framing Error //
output reg Rx_PERROR; // Parity Error //
output reg Rx_VALID; // Rx_DATA is Valid //
wire Rx_sample_ENABLE;
reg [2:0] DATA_counter = 3'b000; //metritis gia thn thesi tou char sto Rx_DATA
reg drive_rxdata = 1'b0;
reg check_errors = 1'b0;
reg [2:0] NextState = 3'b000;
reg [2:0] CurrentState = 3'b000;  
reg [3:0] sample_counter = 4'b0000;
reg [3:0] counter_ones = 4'b0000;
reg data_state = 1'b1;
parameter Rx_idle_state = 3'b000;
parameter Rx_start_bit_state = 3'b001;
parameter Rx_data_state = 3'b010;
parameter Rx_parity_bit_state = 3'b011;
parameter Rx_stop_bit_state = 3'b100;

baud_controller baud_controller_rx_inst(.reset(reset), .clk(clk), .baud_select(baud_select), .sample_ENABLE(Rx_sample_ENABLE));

//sequential fsm - allagi katastasis sthn FSM
always@(posedge clk)
begin
    if(reset == 1)
    begin
        CurrentState <= Rx_idle_state;
    end
    else
    begin
        CurrentState <= NextState;
    end
end

//counter gia tin metrhsh 16 Rx_sample_ENABLE
always@(posedge clk)
begin
    if(reset == 1)
    begin
        sample_counter <= 4'b0000;
    end
    else if(Rx_sample_ENABLE == 1'b1)
    begin
        sample_counter <= sample_counter + 4'b0001;
    end
end

always@(sample_counter)
begin
    if(sample_counter == 4'b1000)
    begin
        check_errors = 1'b1;//elegxei sto meson you kathe bit an einai to swsto
    end
    else if(sample_counter == 4'b1111)
    begin
        drive_rxdata = 1'b1;//odhgei sto epomeno state H' ta rx_data
    end
    else
    begin
        drive_rxdata = 1'b0;
        check_errors = 1'b0;
    end
end

//counter gia thn thesi tou bit sto Rx_DATA
always@(data_state)
begin
    if(reset == 1'b1)
    begin
        DATA_counter = 3'b000;
    end
    else if(data_state == 1'b1)
    begin
        DATA_counter = DATA_counter + 3'b001;
    end
    //else gia na min dimiourgeitai latch
    //begin
    //end
end

//combinational fsm
always@(Rx_EN or drive_rxdata or check_errors or sample_counter or data_state)
begin
    case(CurrentState)
        Rx_idle_state:
        begin
            Rx_VALID = 1'b0;
            Rx_PERROR = 1'b0;
            Rx_FERROR = 1'b0;
      
            if(Rx_EN == 1'b1 && RxD == 1'b0)//eftase to start bit
            begin
               NextState = Rx_start_bit_state;
               received_data = 7'b0000000;
               Rx_DATA = 7'b0000000;
               counter_ones = 4'b0000;
            end
            else
            begin
                NextState = Rx_idle_state;
                received_data = 7'b0000000;
            end
        end
        Rx_start_bit_state:
        begin
            Rx_VALID = 1'b0;
            if (check_errors == 1'b1 && RxD != 1'b0)//elegxos an einai swsto to start bit
            begin 
                Rx_FERROR = 1'b1; //lathos sto start bit
                NextState = Rx_idle_state;
            end 
            else if(drive_rxdata == 1'b1)
            begin
                NextState = Rx_data_state;
                Rx_FERROR = 1'b0;
            end
            else
            begin
              NextState = Rx_start_bit_state;
              Rx_FERROR = 1'b0;
            end
        end
          
        Rx_data_state:
        begin
            data_state = 1'b1;
            Rx_VALID = 1'b0;
            if(sample_counter == 4'b0001)
            begin
                received_data[DATA_counter] = RxD;
            end
            if(check_errors == 1'b1 && received_data[DATA_counter] != RxD)//elegxos sto meson tou bit an einai swsto
            begin
                data_state = 1'b0;
                NextState = Rx_idle_state; 
            end
            else if(drive_rxdata == 1'b1 && DATA_counter < 3'b111) //paei sto epomeno bit
            begin
                data_state = 1'b0;
                if(received_data[DATA_counter] == 1'b1) //counter gia thn katametrhsh twn asswn tou symvolou
                begin
                    counter_ones = counter_ones + 4'b0001;
                end
                NextState = Rx_data_state;
            end
            else if(drive_rxdata == 1'b1 && DATA_counter == 3'b111) //paei sto epomeno state
            begin
                data_state = 1'b0;
                if(received_data[DATA_counter] == 1'b1) //counter gia thn katametrhsh twn asswn tou symvolou
                begin
                    counter_ones = counter_ones + 4'b0001;
                end
                NextState = Rx_parity_bit_state;
            end
            else //deigmatoleiptei ksana to idio mexri == 16
            begin
                NextState = Rx_data_state;
            end
        end

        Rx_parity_bit_state:
        begin
            Rx_VALID = 1'b0;
            if (check_errors == 1'b1 && RxD != counter_ones[0])//elegxos an einai swsto to parity bit
            begin 
                Rx_PERROR = 1'b1; //lathos sto parity bit
                NextState = Rx_idle_state;
            end 
            else if(drive_rxdata == 1'b1)
            begin
                Rx_PERROR = 1'b0;
                NextState = Rx_stop_bit_state;
            end
            else
            begin
                Rx_PERROR = 1'b0;
                NextState = Rx_parity_bit_state;
            end
        end
      
        Rx_stop_bit_state:
        begin
            if (check_errors == 1'b1 && RxD != 1'b1)//elegxos an einai swsto to stop bit
            begin 
                Rx_FERROR = 1'b1; //lathos sto stop bit
                Rx_VALID = 1'b0;
                NextState = Rx_idle_state;
            end 
            else if(drive_rxdata == 1'b1)
            begin
                Rx_FERROR = 1'b0;
                NextState = Rx_idle_state;
                Rx_VALID = 1'b1; //epityxia
                Rx_DATA = received_data;
                received_data = 7'b0000000;
            end
            else
            begin
                Rx_FERROR = 1'b0;
                NextState = Rx_stop_bit_state;
            end       
        end  
        default:
        begin
            Rx_DATA = 7'b0000000;
            NextState = Rx_idle_state; 
        end
    endcase        
end

endmodule
