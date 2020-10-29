`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: MoySys, LLC
// Engineer: Michael Moy
//
// Create Date: 09/13/2020 02:54:34 PM
// Design Name:
// Module Name: top_7seg_Br
// Project Name:
// Target Devices: Br Shield ontop of the Au FPGA base and Serial I/O
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


module top_7seg_Br(
          input clk,
          input rst_n,
          input moyrx, 		   // USB->Serial input
          output moytx, 		   // USB->Serial output
          output [ 7: 0 ] led, 	   // 8 user controllable LEDs
          output wire [ 7: 0 ] io_seg,
          output wire [ 3: 0 ] io_sel
       );

wire [ 7: 0 ] rx_data;
wire rx_avail;
wire rx_err;


wire [ 7: 0 ] tx_data;
wire tx_send;
wire tx_empty;
wire tx_err;

// internal segment data. The Display Controller drives this
wire [ 7: 0 ] io_seg_int;

// digit values to display
wire [ 3: 0 ] val3;
wire [ 3: 0 ] val2;
wire [ 3: 0 ] val1;
wire [ 3: 0 ] val0;

// digit enable flags
wire ena_3 = 1;
wire ena_2 = 1;
wire ena_1 = 1;
wire ena_0 = 1;

// free running counter
reg [ 64: 0 ] counter;

wire [ 15: 0 ] end_counter;


reg [ 15: 0 ] sum;

wire rst;

assign rst = ~rst_n;

// load the Au LED's from the free running counter
assign led[ 7: 2 ] = counter[ 27: 22 ];
assign led[ 1 ] = rx_avail;
assign led[ 0 ] = rx_err;

// wire up the segments as needed. Set DP off:1 for now
assign io_seg[ 0 ] = ~io_seg_int[ 6 ];
assign io_seg[ 1 ] = ~io_seg_int[ 5 ];
assign io_seg[ 2 ] = ~io_seg_int[ 4 ];
assign io_seg[ 3 ] = ~io_seg_int[ 3 ];
assign io_seg[ 4 ] = ~io_seg_int[ 2 ];
assign io_seg[ 5 ] = ~io_seg_int[ 1 ];
assign io_seg[ 6 ] = ~io_seg_int[ 0 ];
assign io_seg[ 7 ] = ~io_seg_int[ 7 ];

// wire up the Io Board 4 Digit 7seg Display Controller
IoBd_7segX4 IoBoard7segDisplay(
               .clk( clk ),
               .reset( rst ),

               .seg3_hex( val3 ),
               .seg3_dp( 0 ),
               .seg3_ena( 1 ),

               .seg2_hex( val2 ),
               .seg2_dp( 0 ),
               .seg2_ena( 1 ),

               .seg1_hex( val1 ),
               .seg1_dp( sha_n ),
               .seg1_ena( 1 ),

               .seg0_hex( val0 ),
               .seg0_dp( rx_err ),
               .seg0_ena( 1 ),

               .bright( 4'h4 ),
               .seg_data( io_seg_int ),
               .seg_select( io_sel )
            );

// RX UART wiring
IoBd_Uart_RX Uart_RX(
                .clk( clk ),
                .rst( rst ),
                .rx_in( moyrx ),
                .data_out( rx_data ),
                .data_avail( rx_avail ),
                .end_counter( end_counter ),
                .data_error( rx_err )
             );

// TX UART wiring
IoBd_Uart_TX Uart_TX(
                .clk( clk ),
                .rst( rst ),
                .tx_out( moytx ),
                .tx_data( tx_data ),
                .tx_rdy( tx_empty ),
                .tx_req( tx_send )
             );

// a cool sha256sum generator, fed by a UART, with results showing
// up on the UART and the 7-SEG display
sha256sum_serial sha256Serial(
                    .clk( clk ),
                    .rst( rst ),
                    .rx_avail( rx_avail ),
                    .rx_data( rx_data ),
                    .tx_empty( tx_empty ),
                    .tx_send( tx_send ),
                    .tx_data( tx_data ),
                    .val3( val3 ),
                    .val2( val2 ),
                    .val1( val1 ),
                    .val0( val0 )
                 );


// keep a free running counter to use for Display Data
always @( posedge clk or negedge rst_n ) begin
	if ( rst_n == 0 ) begin
		counter <= 0;
		end
	else begin
		counter <= counter + 1;
		end
end

endmodule


