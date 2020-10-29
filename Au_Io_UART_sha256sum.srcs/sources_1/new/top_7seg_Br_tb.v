`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 09/13/2020 02:54:34 PM
// Design Name:
// Module Name: top_7seg_Br_tb
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

module top_7seg_Br_tb(
       );

// from the system
reg clk;
reg rst;

// reset signal
wire rst_n;

// these are the controls that run the sha256sum calculation
// UART Recieve wires
wire [ 7: 0 ] rx_data;
wire rx_avail;
wire rx_err;

// UART Transmit wires
wire [ 7: 0 ] tx_data;
wire tx_send;
wire tx_empty;
wire tx_err;



// wires for the Alchitry FPGA + Io board 7-SEG display setup
wire [ 7: 0 ] io_seg;
wire [ 3: 0 ] io_sel;
wire [ 3: 0 ] val3;
wire [ 3: 0 ] val2;
wire [ 3: 0 ] val1;
wire [ 3: 0 ] val0;
wire [ 7: 0 ] io_seg_int;
wire [ 3: 0 ] io_sel_int;

// wire up the reset lines
assign rst_n = ~rst;

// wire up the segments as needed. Set DP off:1 for now
assign io_seg[ 0 ] = ~io_seg_int[ 6 ];
assign io_seg[ 1 ] = ~io_seg_int[ 5 ];
assign io_seg[ 2 ] = ~io_seg_int[ 4 ];
assign io_seg[ 3 ] = ~io_seg_int[ 3 ];
assign io_seg[ 4 ] = ~io_seg_int[ 2 ];
assign io_seg[ 5 ] = ~io_seg_int[ 1 ];
assign io_seg[ 6 ] = ~io_seg_int[ 0 ];
assign io_seg[ 7 ] = ~io_seg_int[ 7 ];
assign io_sel = io_sel_int;

IoBd_7segX4 IoBoard(
               .clk( clk ),
               .reset( ~rst_n ),
               .seg3_hex( val3 ),
               .seg3_dp( 1'b0 ),
               .seg3_ena( 1'b1 ),
               .seg2_hex( val2 ),
               .seg2_dp( 1'b0 ),
               .seg2_ena( 1'b1 ),
               .seg1_hex( val1 ),
               .seg1_dp( 1'b0 ),
               .seg1_ena( 1'b1 ),
               .seg0_hex( val0 ),
               .seg0_dp( 1'd0 ),
               .seg0_ena( 1'b1 ),
               .bright( 4'b0000 ),
               .seg_data( io_seg_int ),
               .seg_select( io_sel_int )
            );

// these are the controls that the TB uses to provide UART input.
reg [ 511: 0 ] rx_sim_data;
reg [ 7: 0 ] rx_sim_len;
reg rx_sim_req;

// simulated UART for the TB so we can pump Test data in real fast and simple
IoBd_Uart_RX_SIM Uart_RX(
                    .clk( clk ),
                    .rst( rst ),
                    .data_sim_512( rx_sim_data ),
                    .data_sim_len( rx_sim_len ),
                    .data_sim_req( rx_sim_req ),
                    .data_out( rx_data ),
                    .data_avail( rx_avail ),
                    .data_error( rx_err )
                 );

// assign tb_usb_rx = tb_usb_tx;
wire tb_usb_tx ;
//
IoBd_Uart_TX Uart_TX(
                .clk( clk ),
                .rst( rst ),
                .tx_out( tb_usb_tx ),
                .tx_data( tx_data ),
                .tx_rdy( tx_empty ),
                .tx_req( tx_send )
             );
/*
stream_sha256 sha256_ctrl(
	.clk(clk),
	.rst_n(rst_n),
	.block_in(TestBlock1),
	.tot_len(TestLen1),
	.sha256_out(Answer),
	.sha256_rdy(sha_rdy),
	.sha256_active(sha_act),
	.sha256_first(sha_f),
	.sha256_next(sha_n),
	.sha256_cs(sha_cs)
	);
   
 */


// free running counter
reg [ 64: 0 ] counter;

// keep a free running counter to use for Display Data
always @( posedge clk ) begin
	if ( rst_n == 0 ) begin
		counter <= 0;
		end
	else begin
		counter <= counter + 1;
		end
end


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


// byte bit lengths:
// 1	8
// 3	24
// 53
// 54
// 55
// 63	504
// 64	512
// 65	512 + 8


initial begin

	$display( " " );
	$display( "-----------------------------------------------------" );
	$display( "--                                                 --" );
	$display( "-- Testbench for Michael Moy                       --" );
	$display( "--                                                 --" );
	$display( "-----------------------------------------------------" );
	$display( "\n" );

	rx_sim_data = 0;
	rx_sim_len = 0;
	rx_sim_req = 0;
	rst = 1;
	clk = 0;
	#50;
	clk = 1;
	#50;
	clk = 0;
	#50;
	clk = 1;
	#50;
	clk = 0;
	#50;
	clk = 1;
	#50;
	clk = 0;
	rst = 0;
	#50;
	clk = 1;
	#50;
	clk = 0;
	#50;

	repeat ( 100 ) begin
		clk = ! clk;
		#50;
		end

	// these work so skip them
	if ( rst == 1 ) begin


		$display( "Test: abc" );
		rx_sim_data = 512'h0000000000000018_0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		//		rx_sim_data = 512'h00000000000001b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		rx_sim_len = 8;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 400 ) begin
			clk = ! clk;
			#50;
			end

		// send the First Block
		rx_sim_data = 512'h616263_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		rx_sim_len = 3;
		//		rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414100_00_0000_0000_0000_0000;
		//		rx_sim_len = 54;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 800 ) begin
			clk = ! clk;
			#50;
			end
		$display( "      %x%x%x%x", val3, val2, val1, val0 );

		// reset then do another test
		rx_sim_data = 0;
		rx_sim_len = 0;
		rx_sim_req = 0;
		rst = 1;
		repeat ( 1000 ) begin
			clk = ! clk;
			#50;
			end
		rst = 0;
		repeat ( 10 ) begin
			clk = ! clk;
			#50;
			end

		$display( "Test: AAA s 0x1b0 54" );
		rx_sim_data = 512'h00000000_000001b0_0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		rx_sim_len = 8;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 400 ) begin
			clk = ! clk;
			#50;
			end
		// send the First Block
		rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414100_00_00000000_00000000;
		rx_sim_len = 54;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 800 ) begin
			clk = ! clk;
			#50;
			end
		$display( "      %x%x%x%x", val3, val2, val1, val0 );




		// reset then do another test
		rx_sim_data = 0;
		rx_sim_len = 0;
		rx_sim_req = 0;
		rst = 1;
		repeat ( 1000 ) begin
			clk = ! clk;
			#50;
			end
		rst = 0;
		repeat ( 10 ) begin
			clk = ! clk;
			#50;
			end


		$display( "Test: AAA s 0x1b8 55" );
		rx_sim_data = 512'h00000000_000001b8_0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		rx_sim_len = 8;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 400 ) begin
			clk = ! clk;
			#50;
			end

		// send the First Block
		rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141_00_00000000_00000000;
		rx_sim_len = 55;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 800 ) begin
			clk = ! clk;
			#50;
			end
		$display( "      %x%x%x%x", val3, val2, val1, val0 );




		// reset then do another test
		rx_sim_data = 0;
		rx_sim_len = 0;
		rx_sim_req = 0;
		rst = 1;
		repeat ( 1000 ) begin
			clk = ! clk;
			#50;
			end
		rst = 0;
		repeat ( 10 ) begin
			clk = ! clk;
			#50;
			end


		$display( "Test: AAA s 0x1b8 56" );
		rx_sim_data = 512'h00000000_000001b8_0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		rx_sim_len = 8;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 400 ) begin
			clk = ! clk;
			#50;
			end

		// send the First Block
		rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414161_00_00000000_00000000;
		rx_sim_len = 56;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 800 ) begin
			clk = ! clk;
			#50;
			end
		$display( "      %x%x%x%x", val3, val2, val1, val0 );


		// reset then do another test
		rx_sim_data = 0;
		rx_sim_len = 0;
		rx_sim_req = 0;
		rst = 1;
		repeat ( 1000 ) begin
			clk = ! clk;
			#50;
			end
		rst = 0;
		repeat ( 10 ) begin
			clk = ! clk;
			#50;
			end


		$display( "Test: AAA s 0x208 65" );
		rx_sim_data = 512'h0000_0000_0000_0208_0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		rx_sim_len = 8;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 400 ) begin
			clk = ! clk;
			#50;
			end

		// send the First Block
		rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141_41_41414141_41414141;
		rx_sim_len = 64;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 800 ) begin
			clk = ! clk;
			#50;
			end


		// send the Second Block
		rx_sim_data = 512'h41000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		//		rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141;
		rx_sim_len = 1;
		rx_sim_req = 1;
		clk = ! clk;
		#50;
		clk = ! clk;
		#50;
		rx_sim_req = 0;
		repeat ( 800 ) begin
			clk = ! clk;
			#50;
			end
		$display( "      %x%x%x%x", val3, val2, val1, val0 );



		// reset then do another test
		rx_sim_data = 0;
		rx_sim_len = 0;
		rx_sim_req = 0;
		rst = 1;
		repeat ( 1000 ) begin
			clk = ! clk;
			#50;
			end
		rst = 0;
		repeat ( 10 ) begin
			clk = ! clk;
			#50;
			end



		//---------------------------------------------------------------------------
		end // these work so skip them
	//---------------------------------------------------------------------------


	$display( "Test: AAA s 0x3a0 116" );
	rx_sim_data = 512'h0000_0000_0000_03a0_0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	rx_sim_len = 8;
	rx_sim_req = 1;
	clk = ! clk;
	#50;
	clk = ! clk;
	#50;
	rx_sim_req = 0;
	repeat ( 400 ) begin
		clk = ! clk;
		#50;
		end

	// send the First Block
	rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141_41_41414141_41414141;
	rx_sim_len = 64;
	rx_sim_req = 1;
	clk = ! clk;
	#50;
	clk = ! clk;
	#50;
	rx_sim_req = 0;
	repeat ( 800 ) begin
		clk = ! clk;
		#50;
		end

	// send the Second Block
	rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141_41_41414141_41414141;
	rx_sim_len = 52; // 64;
	rx_sim_req = 1;
	clk = ! clk;
	#50;
	clk = ! clk;
	#50;
	rx_sim_req = 0;
	repeat ( 800 ) begin
		clk = ! clk;
		#50;
		end
	$display( "      %x%x%x%x", val3, val2, val1, val0 );



	// reset then do another test
	rx_sim_data = 0;
	rx_sim_len = 0;
	rx_sim_req = 0;
	rst = 1;
	repeat ( 1000 ) begin
		clk = ! clk;
		#50;
		end
	rst = 0;
	repeat ( 10 ) begin
		clk = ! clk;
		#50;
		end



	$display( "Test: AAA s 0x9a0 308" );
	rx_sim_data = 512'h0000_0000_0000_09a0_0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	rx_sim_len = 8;
	rx_sim_req = 1;
	clk = ! clk;
	#50;
	clk = ! clk;
	#50;
	rx_sim_req = 0;
	repeat ( 400 ) begin
		clk = ! clk;
		#50;
		end

	// send the First Block
	rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141_41_41414141_41414141;
	rx_sim_len = 64;
	rx_sim_req = 1;
	clk = ! clk;
	#50;
	clk = ! clk;
	#50;
	rx_sim_req = 0;
	repeat ( 800 ) begin
		clk = ! clk;
		#50;
		end

	// send the Second Block
	rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141_41_41414141_41414141;
	rx_sim_len = 64;
	rx_sim_req = 1;
	clk = ! clk;
	#50;
	clk = ! clk;
	#50;
	rx_sim_req = 0;
	repeat ( 800 ) begin
		clk = ! clk;
		#50;
		end

	// send the Second Block
	rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141_41_41414141_41414141;
	rx_sim_len = 64;
	rx_sim_req = 1;
	clk = ! clk;
	#50;
	clk = ! clk;
	#50;
	rx_sim_req = 0;
	repeat ( 800 ) begin
		clk = ! clk;
		#50;
		end

	// send the Second Block
	rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141_41_41414141_41414141;
	rx_sim_len = 64;
	rx_sim_req = 1;
	clk = ! clk;
	#50;
	clk = ! clk;
	#50;
	rx_sim_req = 0;
	repeat ( 800 ) begin
		clk = ! clk;
		#50;
		end

	// send the Second Block
	rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141_41_41414141_41414141;
	rx_sim_len = 52;
	rx_sim_req = 1;
	clk = ! clk;
	#50;
	clk = ! clk;
	#50;
	rx_sim_req = 0;
	repeat ( 800 ) begin
		clk = ! clk;
		#50;
		end
	$display( "      %x%x%x%x", val3, val2, val1, val0 );


	$display( "Done\n" );


	repeat ( 10000 ) begin
		clk = ! clk;
		#50;
		end
	#200;
	clk = ! clk;

	$display( " " );
	$display( "-----------------------------------------------------" );
	$display( "--                                                 --" );
	$display( "-- Testbench Done                                  --" );
	$display( "--                                                 --" );
	$display( "-----------------------------------------------------" );

end


endmodule



