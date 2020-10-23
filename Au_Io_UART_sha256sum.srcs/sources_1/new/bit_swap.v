`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MoySys, LLC
// Engineer: Michael Moy
// 
// Create Date: 10/22/2020 07:40:34 PM
// Design Name: 
// Module Name: bit_swap
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


module bit_swap(
    input [7:0] in_d,
    output [7:0] out_d
    );
    
assign out_d[0] = ~in_d[6];
assign out_d[1] = ~in_d[5];
assign out_d[2] = ~in_d[4];
assign out_d[3] = ~in_d[3];
assign out_d[4] = ~in_d[2];
assign out_d[5] = ~in_d[1];
assign out_d[6] = ~in_d[0];
assign out_d[7] = ~in_d[7];
    
endmodule
