module uart(reset, clk, Tx_wr, Tx_en, rx_en, Tx_data, baud_sel, Tx_D, Tx_busy, rx_ferror, rx_perror, rx_valid, rx_data);
input reset, clk, Tx_wr, Tx_en, rx_en;
input [7:0] Tx_data;
input [2:0] baud_sel;
output Tx_D;
output Tx_busy;
output rx_ferror, rx_perror, rx_valid;
output [7:0] rx_data;

//instantiation twn duo module pou apoteloun to UART 
uart_transmitter uart_transmitter_inst(.reset(reset), .clk(clk), .Tx_DATA(Tx_data), .baud_select(baud_sel), .Tx_WR(Tx_wr), .Tx_EN(Tx_en), .TxD(Tx_D), .Tx_BUSY(Tx_busy));

uart_receiver uart_receiver_inst(.reset(reset), .clk(clk), .baud_select(baud_sel), .Rx_EN(rx_en), .RxD(Tx_D),  .Rx_DATA(rx_data), .Rx_FERROR(rx_ferror), .Rx_PERROR(rx_perror), .Rx_VALID(rx_valid));

endmodule