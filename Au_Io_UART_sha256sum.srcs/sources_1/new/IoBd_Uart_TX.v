`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: MoySys, LLC
// Engineer: Michael Moy
//
// Create Date: 09/28/2020 07:57:48 AM
// Design Name:
// Module Name: IoBd_Uart_TX
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


module IoBd_Uart_TX(
          input clk,
          input rst,
          output reg tx_out,
          input [ 7: 0 ] tx_data,
          output reg tx_rdy,
          input tx_req
       );

// State values and Hold time contant
localparam	STATE_IDLE	= 0, 	// Initial/Reset state
           STATE_WAIT_REQ	= 1,
           STATE_WAIT_START	= 2,
           STATE_SEND_BITS	= 3,
           STATE_SEND_STOP	= 4,
           STATE_OUTPUT_RESULTS	= 5,

           WAIT_BIT_CNT = 868; // 888;


reg [ 2: 0 ] uart_state;
reg [ 15: 0 ] wait_counter;
reg [ 3: 0 ] bit_count;
reg [ 7: 0 ] data;



// tX UART controller State Machine
always @( posedge clk or posedge rst ) begin
	if ( rst ) begin
		wait_counter <= 0;
		bit_count <= 0;
		data <= 0;
		uart_state <= STATE_IDLE;
		tx_rdy <= 0;
		tx_out <= 1;
		end
	else begin
		case ( uart_state )

			STATE_IDLE: begin
				uart_state <= STATE_WAIT_REQ;
				tx_rdy <= 1;
				end

			STATE_WAIT_REQ: begin
				if ( tx_req == 1 ) begin				// lets get started
					uart_state <= STATE_WAIT_START;
					wait_counter <= WAIT_BIT_CNT;
					data <= tx_data;
					tx_out <= 0;
					tx_rdy <= 0;
					end
				end

			STATE_WAIT_START: begin
				if ( wait_counter == 0 ) begin		// START bit done
					uart_state <= STATE_SEND_BITS;
					bit_count <= 0;
					tx_out <= data[ 0 ];
					end
				else begin
					wait_counter <= wait_counter - 1;
					end
				end

			STATE_SEND_BITS: begin
				if ( wait_counter == 0 ) begin			// - done with the bit time. Do we have more bits?
					if ( bit_count == 8 ) begin					// all bits done?
						uart_state <= STATE_SEND_STOP;
						wait_counter <= WAIT_BIT_CNT;
						tx_out <= 1;
						end
					else begin									// get ready to read next bit
						wait_counter <= WAIT_BIT_CNT;
						tx_out <= data[ 0 ];
						bit_count <= bit_count + 1;
						data[ 6: 0 ] <= data[ 7: 1 ];						// shift bits over one spot
						end
					end
				else begin									// - still within a bit time
					wait_counter <= wait_counter - 1;
					end
				end

			STATE_SEND_STOP: begin
				if ( wait_counter == 0 ) begin
					uart_state <= STATE_OUTPUT_RESULTS;
					tx_rdy <= 1;
					end
				else begin									// - still within a bit time
					wait_counter <= wait_counter - 1;
					end
				end

			STATE_OUTPUT_RESULTS: begin
				uart_state <= STATE_WAIT_REQ;
				end
			endcase
		end
end


endmodule
