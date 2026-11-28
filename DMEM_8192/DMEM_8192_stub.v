// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Fri Nov 27 19:13:21 2026
// Host        : HanXian running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Apps/Work/FDU/Vivado/RISCV/RISCV.srcs/sources_1/ip/DMEM_8192/DMEM_8192_stub.v
// Design      : DMEM_8192
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_3,Vivado 2019.1" *)
module DMEM_8192(clka, ena, wea, addra, dina, douta, clkb, enb, web, addrb, 
  dinb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[3:0],addra[12:0],dina[31:0],douta[31:0],clkb,enb,web[3:0],addrb[12:0],dinb[31:0],doutb[31:0]" */;
  input clka;
  input ena;
  input [3:0]wea;
  input [12:0]addra;
  input [31:0]dina;
  output [31:0]douta;
  input clkb;
  input enb;
  input [3:0]web;
  input [12:0]addrb;
  input [31:0]dinb;
  output [31:0]doutb;
endmodule
