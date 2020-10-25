`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MoySys, LLC
// Engineer: Michael Moy
// 
// Create Date: 10/18/2020 07:39:00 PM
// Design Name: 
// Module Name: sha256sum_serial
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: UART driven sha256sum generator.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments
//
// Author: Michael Moy
// Copyright (c) 2020, MoySys, LLC
// All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////////

	 
module sha256sum_serial(
	input            clk,
	input            rst,
	input            rx_avail,
	input [7:0]      rx_data,
	input            tx_empty,
	output reg       tx_send,
	output reg [7:0] tx_data,
	output reg [3:0] val3,
	output reg [3:0] val2,
	output reg [3:0] val1,
	output reg [3:0] val0
	);

wire rst_n;
assign rst_n = ~rst;

// free running counter
reg [64:0] counter;


reg [511:0] TestBlock1;
reg [511:0] PadBlock;
reg  [63:0]  TestLen1;
reg  [63:0]  Test_bits_left;
reg  [63:0] Tot_User_Bit_cnt;
wire [255:0] Answer;	
wire sha_rdy;
wire sha_act;
reg sha_f;
reg sha_n;

reg [7:0] nibbles_left;
reg [255:0] tx_Answer;
reg [255:0] my_Answer;		
reg [7:0] bytes_left;
reg [7:0] bytes_pad;

reg [7:0] state_256_serial;


reg sha_eod_done;

wire sha_cs;

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




// state machine
always @(posedge clk or negedge rst_n) begin

	if(rst_n == 0) begin
		state_256_serial <= 0;
		sha_f <= 0;
		sha_n <= 0;  
		val3 <= 0;
		val2 <= 0;
		val1 <= 0;
		val0 <= 0;
		tx_data <= 8'h31;
		TestBlock1 <= 0;
		Test_bits_left <= 0 ;
		TestLen1 <= 0;
		PadBlock <= 0; 
		Tot_User_Bit_cnt <= 0;
		bytes_left <= 8;
		sha_eod_done <= 0;
		end

	else begin // Rising edge of clock

		case(state_256_serial)
		
		
			// read in data from the UART for the Total User Data bit count, in hex.
			0: begin
			
				 // keep reading
				if( bytes_left != 0 ) begin
				
					if( rx_avail ) begin 
						Tot_User_Bit_cnt[63:8] <= Tot_User_Bit_cnt[55:0];
						Tot_User_Bit_cnt[7:0] <= rx_data;
						bytes_left <= bytes_left - 1;
						end
					end
					
				 // got them all
				else begin
				
					// calculate the total bits to work on and the padded total bit count
					Test_bits_left <= Tot_User_Bit_cnt;
					TestLen1 <= (Tot_User_Bit_cnt & 64'hffff_fe00) + (Tot_User_Bit_cnt[8:0] > (512-64-8) ? 1024 : 512);	
					
					// set the number of UART bytes to read in the first round
					if( Tot_User_Bit_cnt >= 512 ) begin
						bytes_left <= 64;
						bytes_pad <= 0;
						end
					else begin
//						bytes_left <= Tot_User_Bit_cnt[10:3];
//						bytes_pad <= 64 - Tot_User_Bit_cnt[10:3];
						bytes_left[7] <= 0;
						bytes_left[6:0] <= Tot_User_Bit_cnt[9:3];
						bytes_pad <= 64 - Tot_User_Bit_cnt[9:3];
						end		
							
					// go get a block
					state_256_serial <= 14;
					
					end
				end
				
			// read in User data from the UART for the Data block of up to 512 bits
			14: begin
			
				// keep reading
				if( bytes_left != 0 ) begin				
					if( rx_avail ) begin 
						TestBlock1[511:8] <= TestBlock1[503:0];
						TestBlock1[7:0] <= rx_data;
						bytes_left <= bytes_left - 1;
						end
					end
					
				// got all the User data the UART has available
				else begin
				
					// pad out the rest of the 512 if needed
					if( bytes_pad != 0 ) begin
						TestBlock1[511:8] <= TestBlock1[503:0];
						TestBlock1[7:0] <= 0;
						bytes_pad <= bytes_pad - 1;
						end
						
					// do block updates that are needed before sending it on
					else begin
						
						if( Test_bits_left < 512 ) begin
						
							// ends in this block with room for the EOD and Total Bit Count values
							if( Test_bits_left <= (512-64-8) && Tot_User_Bit_cnt[8:0] != 0 ) begin
								TestBlock1[63:0] <= Tot_User_Bit_cnt;
								if( sha_eod_done == 0 ) begin
									TestBlock1[ (512-8-Test_bits_left) +: 8] <= 8'h80;
									sha_eod_done <= 1 ;
									end
								state_256_serial <= 2;
								end
							
							else begin
							
								// ended, so put in Total Bit Count and the EOD if it is needed
								if( Test_bits_left == 0 ) begin
									TestBlock1[63:0] <= Tot_User_Bit_cnt;
									if( sha_eod_done == 0 ) begin
										TestBlock1[511:504] <= 8'h80;
										sha_eod_done <= 1 ;
										end
									TestBlock1[503:64] <= 0;
									state_256_serial <= 2;
									end
									
								// EOD is in this block but not the Total Bit Count
								else begin
									if( sha_eod_done == 0 ) begin
										TestBlock1[ (512-8-Test_bits_left) +: 8] <= 8'h80;
										sha_eod_done <= 1 ;
										end
									state_256_serial <= 15;
									end
								end
							end
						else begin
							state_256_serial <= 15;	
							Test_bits_left <= Test_bits_left - 512 ;
							end					
						end
					end	
				end
				
			// wait for the block to get pulled in
			15: begin
				
				if( sha_act == 1 && sha_cs == 0 ) begin
				
					state_256_serial <= 14;  
					 
					sha_f <= 0; 
					sha_n <= 0;

					// also the number of bytes to get in this round
					if( Test_bits_left >= 512 ) begin
						bytes_left <= 64;	// number of bytes for first 512 bits of data.
						bytes_pad <= 0;
						end
					else begin
						bytes_left[7:6] <= 0;
						bytes_left[5:0] <= Tot_User_Bit_cnt[8:3];
						bytes_pad <= 64 - Tot_User_Bit_cnt[8:3];
						end		
					TestBlock1 <= 0;    
					end
				else begin
/* Here or below?? */					sha_f <= 1; // needs to be set to get this last on pulled.		
					end					
			
				end


			// wait for the last User Block to get finished and do the Padded Block next
			2: begin
			
				if( sha_act == 1 && sha_cs == 0 ) begin
					state_256_serial <= 3;            
					sha_n <= 0; 
					sha_f <= 0;		
					end
				else begin
					sha_f <= 1; // needs to be set to get this last on pulled.		
					end
				end

			3: begin
			
				if( sha_rdy != 0 ) begin
					state_256_serial <= 4;	
					end
				end

			4: begin
				
					state_256_serial <= 5;
					nibbles_left <= 64;
					tx_Answer <= Answer;
					my_Answer <= Answer;	
					val3 <= Answer[255 : 252];
					val2 <= Answer[251 : 248];
					val1 <= Answer[247 : 244];
					val0 <= Answer[243 : 240];
				end
				


			// print out the answer in ASCII using the UART
			5: begin
			
				if( nibbles_left == 0 ) begin
					state_256_serial <= 6;	
					tx_send <= 0;
					end
				else begin
					if( rx_avail && tx_empty && tx_send == 0 ) begin
						tx_data <= (tx_Answer[255:252] <= 9 ? (tx_Answer[255:252]+8'h30) : (tx_Answer[255:252] - 10 + 8'h61) );  // hex to ASCII
						nibbles_left <= nibbles_left - 1;				
						tx_send <= 1;
						tx_Answer[255:4] <= tx_Answer[251:0];
						end
					else begin
						tx_send <= 0;
						end
					end
				end

			// print out a <lf>
			6: begin
			
				if( tx_empty && tx_send == 0 ) begin
					tx_data <= 8'h0a;		
					tx_send <= 1;
					state_256_serial <= 7;	
					end
				else begin
					tx_send <= 0;
					end
				end

			7: begin
			
					tx_send <= 0;
			
					// start over and get another request
					state_256_serial <= 0;
					sha_f <= 0;
					sha_n <= 0;
					TestBlock1 <= 0;
					Test_bits_left <= 0 ;
					TestLen1 <= 0;
					PadBlock <= 0; 
					Tot_User_Bit_cnt <= 0;
					bytes_left <= 8;
					sha_eod_done <= 0;
									
				end	
							
			default: begin			
				val3 <= state_256_serial[3:0];
			end
						
		endcase
		
	end
end

endmodule


