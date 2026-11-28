`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/27 15:49:47
// Design Name: 
// Module Name: MA
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


module MA(
    input clk,
    input rst,
    // MA输入信号
    input [31:0] pc_MA,
    input [31:0] ALU_MA,
    input [31:0] rs2_MA,
    input [31:0] inst_MA,
    // 组合逻辑控制信号              当前认为DMEM b端口（CPU端口）使能enb恒为1，需要保证只要非write情况下，write_in_mode信号必须为0000         
    input [1:0] data_sel,           // data数据选择器控制信号：00来自内存，01来自ALU_MA，10来自PC+4
    input [3:0] write_in_mode,      // 写入使能信号：0000读取（不写入），0001写入最低字节，0011写入半字，1111写入完整32位
    input [2:0] load_funct3,        // 读数时符号位扩展控制信号 
    // 写入DMEM信号（来自外部）
    input [3:0] A_write_in_mode,
    input [31:0] A_data_in,
    input [12:0] A_addr,
    input ena,
    // 读回DMEM信号（来自外部）
    output [31:0] A_data_out,
    // MA输出信号
    output [31:0] data_WB,  
    output reg [31:0] inst_WB
    );

    localparam NOP = 32'h0000_0013;

    wire [12:0] Addr_of_Word;
    wire [1:0] Addr_Byte_low;
    wire [31:0] data_B;
    wire [31:0] data_extended;
    reg [31:0] data_other;
    reg sel;
    reg [2:0] load_funct3_reg;
    reg [1:0] Addr_Byte_low_reg;

    assign Addr_of_Word = ALU_MA >> 2;
    assign Addr_Byte_low = ALU_MA[1:0];

    DMEM_8192 U_DMEM (
        // A端口，外部信号读写
        .clka(clk),
        .addra(A_addr),
        .dina(A_data_in),
        .douta(A_data_out),
        .ena(ena),
        .wea(A_write_in_mode),

        // B端口，CPU内部信号读写
        .clkb(clk),
        .addrb(Addr_of_Word),
        .dinb(rs2_MA << {Addr_Byte_low, 3'b000}),
        .doutb(data_B),
        .enb(1'b1),
        .web(write_in_mode)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            inst_WB <= NOP;
            load_funct3_reg <= 2'd0;
            Addr_Byte_low_reg <= 1'd0;
            data_other <= 32'd0;
            sel <= 1'b0;
        end
        else begin
            inst_WB <= inst_MA;
            load_funct3_reg <= load_funct3;
            Addr_Byte_low_reg <= Addr_Byte_low;
            sel <= (data_sel == 2'b00);
            case (data_sel)
                2'b01: data_other <= ALU_MA;
                2'b10: data_other <= pc_MA + 32'd4;
                default: data_other <= 32'd0;
            endcase
        end
    end

    load_extend U_load_extend (
        .funct3(load_funct3_reg),
        .data_in(data_B),
        .Addr_low(Addr_Byte_low_reg),
        .data_extended(data_extended)
    );


    assign data_WB = sel ? data_extended : data_other;

endmodule
