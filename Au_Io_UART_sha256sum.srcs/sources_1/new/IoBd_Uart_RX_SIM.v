`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: MoySys, LLC
// Engineer: Michael Moy
//
// Create Date: 10/19/2020 08:01:00 AM
// Design Name:
// Module Name: IoBd_Uart_RX_SIM
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
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

module IoBd_Uart_RX_SIM(

          input clk,
          input rst,
          input [ 511: 0 ] data_sim_512,
          input [ 7: 0 ] data_sim_len,
          input data_sim_req,
          output reg [ 7: 0 ] data_out,
          output reg data_avail,
          output reg data_error
       );

// locals
reg [ 3: 0 ] state_rx_sim;
reg [ 511: 0 ] int_data_sim_512;
reg [ 7: 0 ] int_data_sim_len;


// state machine to simulate UART input data
always @( posedge clk or posedge rst ) begin
	if ( rst == 1 ) begin
		state_rx_sim <= 0;
		data_out <= 8'h41;
		data_avail <= 0;
		data_error <= 0;
		end
	else begin
		case ( state_rx_sim )
			0: begin // wait for a request
				if ( data_sim_req == 1 ) begin // copy the input to a local buffer
					state_rx_sim <= 1;
					int_data_sim_512 <= data_sim_512;
					int_data_sim_len <= data_sim_len;
					end
				end
			1: begin // pass it to the user, bump the counter and signal for ONE CLK length that we have data
				data_out <= int_data_sim_512[ 511: 504 ];
				int_data_sim_512[ 511: 8 ] <= int_data_sim_512[ 503: 0 ];
				int_data_sim_len <= int_data_sim_len - 1;
				data_avail <= 1;
				state_rx_sim <= 2;
				end
			2: begin // stall a few clocks. Some users expect slower input
				data_avail <= 0;
				state_rx_sim <= 3;
				end
			3: begin
				state_rx_sim <= 4;
				end
			4: begin // see if we are done or need to give the next byte
				if ( int_data_sim_len == 0 )
					state_rx_sim <= 5;
				else
					state_rx_sim <= 1;
				end
			5: begin // one last stall
				state_rx_sim <= 0;
				end
			endcase

		end
end

endmodule


