//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.1.1 (win64) Build 2960000 Wed Aug  5 22:57:20 MDT 2020
//Date        : Sat Oct 24 12:07:02 2020
//Host        : winonssd running 64-bit major release  (build 9200)
//Command     : generate_target Au_Io_UART_sha256sum_1_wrapper.bd
//Design      : Au_Io_UART_sha256sum_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module Au_Io_UART_sha256sum_1_wrapper
   (clk,
    io_seg,
    io_sel,
    moyrx,
    moytx,
    rst_n);
  input clk;
  output [7:0]io_seg;
  output [3:0]io_sel;
  input moyrx;
  output moytx;
  input rst_n;

  wire clk;
  wire [7:0]io_seg;
  wire [3:0]io_sel;
  wire moyrx;
  wire moytx;
  wire rst_n;

  Au_Io_UART_sha256sum_1 Au_Io_UART_sha256sum_1_i
       (.clk(clk),
        .io_seg(io_seg),
        .io_sel(io_sel),
        .moyrx(moyrx),
        .moytx(moytx),
        .rst_n(rst_n));
endmodule
