`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: MoySys, LLC
// Engineer: Michael Moy
//
// Create Date: 09/27/2020 09:46:46 PM
// Design Name:
// Module Name: IoBd_Uart_RX
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision: 2.0 10/12/2020
// Additional Comments: Rebuilt in a simpler form with a BAUD rate counter
// detector circuit built in for determining counter trip values.
//
//////////////////////////////////////////////////////////////////////////////////


module IoBd_Uart_RX(
          input clk,
          input rst,
          input rx_in,
          output reg [ 7: 0 ] data_out,
          output reg data_avail,
          output reg [ 15: 0 ] end_counter,
          output reg data_error
       );


reg [ 15: 0 ] wait_counter;
reg	running;



always @( posedge clk or posedge rst ) begin
	if ( rst ) begin
		running <= 0;
		data_avail <= 0;
		data_out <= 8'h00;
		end
	else begin
		if ( running == 0 ) begin
			data_avail <= 0;
			if ( rx_in == 0 ) begin
				running <= 1;
				end
			end
		if ( running == 1 && wait_counter == ( 433 + ( 866 * 1 ) ) ) begin
			data_out[ 0 ] <= rx_in;
			end
		if ( running == 1 && wait_counter == ( 433 + ( 866 * 2 ) ) ) begin
			data_out[ 1 ] <= rx_in;
			end
		if ( running == 1 && wait_counter == ( 433 + ( 866 * 3 ) ) ) begin
			data_out[ 2 ] <= rx_in;
			end
		if ( running == 1 && wait_counter == ( 433 + ( 866 * 4 ) ) ) begin
			data_out[ 3 ] <= rx_in;
			end
		if ( running == 1 && wait_counter == ( 433 + ( 866 * 5 ) ) ) begin
			data_out[ 4 ] <= rx_in;
			end
		if ( running == 1 && wait_counter == ( 433 + ( 866 * 6 ) ) ) begin
			data_out[ 5 ] <= rx_in;
			end
		if ( running == 1 && wait_counter == ( 433 + ( 866 * 7 ) ) ) begin
			data_out[ 6 ] <= rx_in;
			end
		if ( running == 1 && wait_counter == ( 433 + ( 866 * 8 ) ) ) begin
			data_out[ 7 ] <= rx_in;
			end
		if ( running == 1 && wait_counter == ( 433 + ( 866 * 9 ) ) ) begin
			running <= 0;
			data_error <= ~rx_in;
			data_avail <= 1;
			end
		end
end

always @( posedge clk or posedge rst ) begin
	if ( rst || data_avail == 1 ) begin
		wait_counter <= 0;
		end
	else begin
		if ( running == 1 ) begin
			wait_counter <= wait_counter + 1;
			end
		end
end

always @( posedge clk or posedge rst ) begin
	if ( rst ) begin
			end_counter <= 0;
		end
	else begin
		if ( running == 1 && rx_in == 0 ) begin
				end_counter <= wait_counter;
			end
		end
end

endmodule

