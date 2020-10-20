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
    reg  rst;   
	wire rst_n;

 
    wire [7:0] rx_data;
	wire rx_avail;
	wire rx_err;
    
    wire [7:0] tx_data;
	wire tx_send;
	wire tx_empty;
	wire tx_err;
     
    // Output
	wire[7:0] io_seg;
	wire [3:0] io_sel;

    
wire [3:0] val3; 
wire [3:0] val2;   
wire [3:0] val1;   
wire [3:0] val0;      

assign rst_n = ~rst;


wire [6:0] io_seg_int;
wire [3:0] io_sel_int;

// wire up the segments as needed. Set DP off:1 for now
assign io_seg[0] = ~io_seg_int[6];
assign io_seg[1] = ~io_seg_int[5];
assign io_seg[2] = ~io_seg_int[4];
assign io_seg[3] = ~io_seg_int[3];
assign io_seg[4] = ~io_seg_int[2];
assign io_seg[5] = ~io_seg_int[1];
assign io_seg[6] = ~io_seg_int[0];
assign io_seg[7] = ~io_seg_int[7];

assign io_sel = io_sel_int;
 
IoBd_7segX4 IoBoard(
	.clk(clk),
	.reset(~rst_n),
	.seg3_hex(val3),
	.seg3_dp(1'b0),
	.seg3_ena(1'b1),
	.seg2_hex(val2),
	.seg2_dp(1'b0),
	.seg2_ena(1'b1),
	.seg1_hex(val1),
	.seg1_dp(1'b0),
	.seg1_ena(1'b1),
	.seg0_hex(val0),
	.seg0_dp(1'd0),
	.seg0_ena(1'b1),
	.bright(4'b0000),
	.seg_data(io_seg_int[6:0]),
	.seg_select(io_sel_int)
	);   
       
reg [511:0] rx_sim_data;
reg [7:0]   rx_sim_len;
reg         rx_sim_req;


IoBd_Uart_RX_SIM Uart_RX(
    .clk(clk),
    .rst(rst),
    .data_sim_512(rx_sim_data),
    .data_sim_len(rx_sim_len),
    .data_sim_req(rx_sim_req),
    .data_out(rx_data),
    .data_avail(rx_avail),
    .data_error(rx_err)
    );

assign tb_usb_rx = tb_usb_tx;


IoBd_Uart_TX Uart_TX(
    .clk(clk),
    .rst(rst),
    .tx_out(tb_usb_tx),
    .tx_data(tx_data ),
    .tx_rdy(tx_empty),
    .tx_req(tx_send)
    );
	    
 
// free running counter
reg [64:0] counter;

wire [15:0] end_counter;

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
   
 
// keep a free running counter to use for Display Data
always @(posedge clk) begin
	if(rst_n == 0) begin
		counter <= 0;
		end
	else begin
		counter <= counter + 1;
		end
	end


sha256sum_serial sha256Serial(
	.clk(clk),
	.rst(rst),

	.rx_avail(rx_avail),
	.rx_data(rx_data),

	.tx_empty(tx_empty),	
	.tx_send(tx_send),
	.tx_data(tx_data),

	.val3(val3),
	.val2(val2),
	.val1(val1),
	.val0(val0)
    );




/*


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

reg [7:0] state;
reg [7:0] nibbles_left;
reg [255:0] tx_Answer;
reg [255:0] my_Answer;		
reg [7:0] bytes_left;
reg [7:0] bytes_pad;

wire sha_cs;



		
// state machine
always @(posedge clk) begin

	if(rst_n == 0) begin
		state <= 0;
		sha_f <= 0;
		sha_n <= 0;
		val3 <= 0;
		val2 <= 0;
		val1 <= 0;
		val0 <= 0;
//		TestLen1 <= 1024 + 512;
		TestLen1 <= 512;
		tx_send <= 0;
		daVal <= 8'h41;
		sum <= 0;
		bytes_left <= 64;
		TestBlock1 <= 0;  		
		end
				
	else begin // Rising edge of clock

		case(state)
			0: begin
					
				// fixed test value					
//	    		TestBlock1 <= 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141;
	    		TestBlock1 <= 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
				state <= 1;
				end

			1: begin
				state <= 15;
				sha_f <= 1;
				end
				
			15: begin
				if( sha_act == 1 && sha_cs == 0 ) begin
//	    			TestBlock1 <= 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141;
//					state <= 2;
					state <= 3;          
					sha_f <= 0;
//					sha_n <= 1;  
					end
				end

			2: begin
				if( sha_act == 1 && sha_cs == 0 ) begin
					state <= 3;      
	  				TestBlock1 <= 512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400;
					end
				end

			3: begin
				if( sha_rdy != 0 ) begin
					state <= 4;	
	sha_n <= 0;  			
					end
				else begin 		
					end
				end

			4: begin	
					state <= 5;
					nibbles_left <= 64;
					tx_Answer <= Answer;	
				end

			// print out the answer in ASCII using the UART
			5: begin
				if( nibbles_left == 0 ) begin
					state <= 6;	
					tx_send <= 0;
					end
				else begin
					if( tx_empty && tx_send == 0 ) begin
						daVal <= (tx_Answer[255:252] <= 9 ? (tx_Answer[255:252]+8'h30) : (tx_Answer[255:252] - 10 + 8'h61) );  // hex to ASCII
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
					daVal <= 8'h0a;		
					tx_send <= 1;
					state <= 7;	
					end
				else begin
					tx_send <= 0;
					end
				end

			7: begin
					tx_send <= 0;	
					if( counter[29:28] == 0 ) begin
						val3 <= Answer[255 : 252];
						val2 <= Answer[251 : 248];
						val1 <= Answer[247 : 244];
						val0 <= Answer[243 : 240];
						end
					else  if( counter[29:28] == 1 ) begin
						val3 <= Answer[239 : 236];
						val2 <= Answer[235 : 232];
						val1 <= Answer[231 : 228];
						val0 <= Answer[227 : 224];
						end
					else  if( counter[29:28] == 2 ) begin
						val3 <= Answer[223 : 220];
						val2 <= Answer[219 : 216];
						val1 <= Answer[215 : 212];
						val0 <= Answer[211 : 208];
						end
					else begin
						val3 <= Answer[207 : 204];
						val2 <= Answer[203 : 200];
						val1 <= Answer[199 : 196];
						val0 <= Answer[195 : 192];
						end
				end
		endcase

	end
end
	    
*/
 /*
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

reg [7:0] state;
reg [7:0] nibbles_left;
reg [255:0] tx_Answer;
reg [255:0] my_Answer;		
reg [7:0] bytes_left;
reg [7:0] bytes_pad;

wire sha_cs;
	
// state machine
always @(posedge clk or negedge rst_n) begin

	if(rst_n == 0) begin
		state <= 0;
		sha_f <= 0;
		sha_n <= 0;  
		val3 <= 0;
		val2 <= 0;
		val1 <= 0;
		val0 <= 0;
		tx_send <= 0;
		daVal <= 8'h41;
		sum <= 0;
		bytes_left <= 8;
		TestBlock1 <= 0;
		Test_bits_left <= 0 ;
		TestLen1 <= 0;
		PadBlock <= 512'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000; 
		Tot_User_Bit_cnt <= 0;
		 		
		end
				
	else begin // Rising edge of clock

		case(state)
			0: begin
		
				// read in data from the UART for the: Total User Data bit count, in hex.
				//
				// Does not include padding. The number of padded bytes is calculated from this.
				// 64 bits as 8 x 8-bit bytes.  1024 User Data bits would be in hex: 00 00 00 00 00 00 04 00
				// After padding, the TestLen1 value is larger and a multiple of 512.
				if( bytes_left == 0 ) begin
					state <= 8;
					
					// now calculate the total number of bits INCLUDING the padding
					Test_bits_left <= Tot_User_Bit_cnt;
					TestLen1 <= (Tot_User_Bit_cnt < 512 ? 512 : ( Tot_User_Bit_cnt < 1024 ? 1024 : (1024+512) )) + (Tot_User_Bit_cnt[8:0] > (512-64-8) ? 512 : 0);	
					
					// also the number of bytes to get inthe first round
					if( Tot_User_Bit_cnt >= 512 ) begin
						bytes_left <= 64;	// number of bytes for first 512 bits of data.
						bytes_pad <= 0;
						end
					else begin
						bytes_left <= Tot_User_Bit_cnt[10:3];
						bytes_pad <= 64 - Tot_User_Bit_cnt[10:3];
						end		
													
					end
				else begin
					if( rec_avail ) begin 
						Tot_User_Bit_cnt[63:8] <= Tot_User_Bit_cnt[55:0];
						Tot_User_Bit_cnt[7:0] <= rec_data;
						bytes_left <= bytes_left - 1;
						end
					end
				end
				
			8: begin
			
				// read in data from the UART for the: First Data blcok of 512 bits, in hex.
				//	
				if( bytes_left == 0 ) begin
					if( bytes_pad != 0 ) begin
						TestBlock1[511:8] <= TestBlock1[503:0];
						TestBlock1[7:0] <= 0;
						bytes_pad <= bytes_pad - 1;
						end
					else begin
				state <= 14;
//				sha_f <= 1;
			//			state <= 1;
			//			bytes_left <= 64;	// number of bytes for first 512 bits of data.
					end
					end
				else begin
					if( rec_avail ) begin 
						TestBlock1[511:8] <= TestBlock1[503:0];
						TestBlock1[7:0] <= rec_data;
						bytes_left <= bytes_left - 1;
						end
					end			
									
				// fixed test value					
//	    		TestBlock1 <= 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141;
//				state <= 1;
				end

			// Send the first block
			1: begin
				state <= 15;
				sha_f <= 1;
				if( Test_bits_left >= 512 )
					Test_bits_left <= Test_bits_left - 512 ;
						
				end
				
				
				
			// wait for the block to get in
			15: begin
				val2 <= Test_bits_left[11:8];
				val1 <= Test_bits_left[7:4];
				val0 <= Test_bits_left[3:0];
				
				if( sha_act == 1 && sha_cs == 0 ) begin
	    			TestBlock1 <= 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141;
					if( Test_bits_left >= 512 )
						Test_bits_left <= Test_bits_left - 512 ;
					else
						Test_bits_left <= 0;
					state <= 14;   
					sha_f <= 0; 
					sha_n <= 0;

					// also the number of bytes to get in this round
					if( Test_bits_left >= 512 ) begin
						bytes_left <= 64;	// number of bytes for first 512 bits of data.
						bytes_pad <= 0;
						end
					else begin
						bytes_left <= Tot_User_Bit_cnt[10:3];
						bytes_pad <= 64 - Tot_User_Bit_cnt[10:3];
						end		
			TestBlock1 <= 0;    
					end
			
				end
				
			14: begin
			
				// read in data from the UART for the: Next Data blcok of 512 bits, in hex.
				//
				
sha_n <= 1; 	
				if( bytes_left == 0 ) begin
				
					if( bytes_pad != 0 ) begin
						TestBlock1[511:8] <= TestBlock1[503:0];
						TestBlock1[7:0] <= 0;
						bytes_pad <= bytes_pad - 1;
						end
					else begin
				
//						if( Tot_User_Bit_cnt > (512-64-8) )
//							sha_n <= 1; 
						
						if( Test_bits_left < 512 ) begin
						
							if( Test_bits_left < (512-64-8) && Tot_User_Bit_cnt[8:0] != 0 ) begin
								TestBlock1[63:0] <= Tot_User_Bit_cnt;
								TestBlock1[ (512-8-Test_bits_left) +: 8] <= 8'h80;
								state <= 2;
								end
							else begin
								if( Test_bits_left == 0 ) begin
									TestBlock1[63:0] <= Tot_User_Bit_cnt;
		// sometimes not needed
									TestBlock1[511:504] <= 8'h80;
									TestBlock1[503:64] <= 0;
								state <= 2;
									end
								else begin
									TestBlock1[ (512-8-Test_bits_left) +: 8] <= 8'h80;
									state <= 15;
									end
								end
							end
						else begin
							state <= 15;
//							Test_bits_left <= Test_bits_left - 512 ;
							end					
						end
					end
				else begin
					if( rec_avail ) begin 
						TestBlock1[511:8] <= TestBlock1[503:0];
						TestBlock1[7:0] <= rec_data;
						bytes_left <= bytes_left - 1;
						
				
						end
					end	
				end		


			// wait for the last User Block to get finished and do the Padded Block next
			2: begin
				if( sha_act == 1 && sha_cs == 0 ) begin
					state <= 3;            
//	  				TestBlock1 <= PadBlock; // 512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400;
					sha_n <= 0; 
	sha_f <= 0;		
					end
				else begin
//					sha_n <= 0; 

	sha_f <= 1;		
					end
				end

			3: begin
				if( sha_rdy != 0 ) begin
					state <= 4;	
					end
				end

			4: begin			
					state <= 5;
					nibbles_left <= 64;
					tx_Answer <= Answer;
					my_Answer <= Answer;		
				end

			// print out the answer in ASCII using the UART
			5: begin
				if( nibbles_left == 0 ) begin
					state <= 6;	
					tx_send <= 0;
					end
				else begin
					if( rec_avail && tx_empty && tx_send == 0 ) begin
						daVal <= (tx_Answer[255:252] <= 9 ? (tx_Answer[255:252]+8'h30) : (tx_Answer[255:252] - 10 + 8'h61) );  // hex to ASCII
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
					daVal <= 8'h0a;		
					tx_send <= 1;
					state <= 7;	
					end
				else begin
					tx_send <= 0;
					end
				end

			7: begin
					tx_send <= 0;	
					if( counter[29:28] == 0 ) begin
						val3 <= my_Answer[255 : 252];
						val2 <= my_Answer[251 : 248];
						val1 <= my_Answer[247 : 244];
						val0 <= my_Answer[243 : 240];
						end
					else  if( counter[29:28] == 1 ) begin
						val3 <= my_Answer[239 : 236];
						val2 <= my_Answer[235 : 232];
						val1 <= my_Answer[231 : 228];
						val0 <= my_Answer[227 : 224];
						end
					else  if( counter[29:28] == 2 ) begin
						val3 <= my_Answer[223 : 220];
						val2 <= my_Answer[219 : 216];
						val1 <= my_Answer[215 : 212];
						val0 <= my_Answer[211 : 208];
						end
					else begin
						val3 <= my_Answer[207 : 204];
						val2 <= my_Answer[203 : 200];
						val1 <= my_Answer[199 : 196];
						val0 <= my_Answer[195 : 192];
						end
				end
		endcase

	end
end
*/
  
    
    initial begin

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

        repeat (100) begin
            clk =  ! clk;
            #50;
        end
        

// send the bit count
//		rx_sim_data = 512'h00000000000000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		rx_sim_data = 512'h00000000000001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		rx_sim_len = 8;
		rx_sim_req = 1;
        clk =  ! clk;
        #50;
        clk =  ! clk;
        #50;
		rx_sim_req = 0;
        repeat (400) begin
            clk =  ! clk;
            #50;
        end
 
		// send the First Block
//		rx_sim_data = 512'h61626300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141416141410000000000000000;
		rx_sim_len = 56; // 64;
		rx_sim_req = 1;
        clk =  ! clk;
        #50;
        clk =  ! clk;
        #50;
		rx_sim_req = 0;
        repeat (800) begin
            clk =  ! clk;
            #50;
        end


	
 /*
		// send the Second Block
		rx_sim_data = 512'h41414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141;
		rx_sim_len = 64;
		rx_sim_req = 1;
        clk =  ! clk;
        #50;
        clk =  ! clk;
        #50;
		rx_sim_req = 0;
        repeat (250) begin
            clk =  ! clk;
            #50;
        end
*/	
		
        repeat (100000) begin
            clk =  ! clk;
            #50;
        end
        #200;
        clk =  ! clk;
        end
            
endmodule



