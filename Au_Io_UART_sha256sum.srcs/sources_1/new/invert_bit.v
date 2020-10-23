`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MoySys, LLC
// Engineer: Michael Moy
// 
// Create Date: 10/22/2020 07:57:15 PM
// Design Name: 
// Module Name: invert_bit
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


module invert_bit(
    input in_val,
    output out_val
    );
    
 assign out_val = ~in_val;
    
endmodule
