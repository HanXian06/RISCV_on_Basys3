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
    input [31:0] pc_MA,             // EX -> MA 流水线寄存器
    input [31:0] ALU_MA,            // EX -> MA 流水线寄存器
    input [31:0] rs2_MA,            // EX -> MA 流水线寄存器
    input [31:0] inst_MA,           // EX -> MA 流水线寄存器
    // 组合逻辑控制信号              当前认为DMEM b端口（CPU端口）使能enb恒为1，需要保证只要非write情况下，write_in_mode信号必须为0000         
    input [1:0] data_sel,           // data数据选择器控制信号：00来自内存，01来自ALU_MA，10来自PC+4
    input [3:0] write_in_mode,      // 写入使能信号：0000读取（不写入），0001写入最低字节，0011写入半字，1111写入完整32位
    input [2:0] load_funct3,        // 读数时符号位扩展控制信号 
    // 写入DMEM信号（来自外部）
    input [3:0] A_write_in_mode,    // 外部写使能控制信号，对应DMEM wea
    input [31:0] A_data_in,         // 外部输入数据
    input [12:0] A_addr,            // 外部输入地址
    input ena,                      // 外部使能
    // 读回DMEM信号（来自外部）
    output [31:0] A_data_out,       // 外部读取数据
    // MA输出信号
    output [31:0] data_WB,          // MA -> WB 流水线寄存器
    output reg [31:0] inst_WB       // MA -> WB 流水线寄存器
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

    assign Addr_of_Word = ALU_MA >> 2;              // 字（32bit）对应地址，即ALU_MA计算得到的是字节地址，需右移2位
    assign Addr_Byte_low = ALU_MA[1:0];             // 字节偏移，对应ALU_MA计算得到地址的最低2位，对应当前字内的第0~3个Byte

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
        .addrb(Addr_of_Word),                       // 按字读取（DMEM读取宽度为32bit）
        .dinb(rs2_MA << {Addr_Byte_low, 3'b000}),   // 针对S-Type：若写入为rs2_MA的低8/16位，写入的位置需通过字节偏移计算，通过左移，将低8/16位数据移至对应位置
        .doutb(data_B),                             // 注意：输出的data_B已经打了一拍（和要输出的data_WB已经在同一拍上了）
        .enb(1'b1),                                 // 默认enb始终为1，若指令不访存，要求web必须为0000
        .web(write_in_mode)                         // 0000读取（不写入），0001写入最低字节，0011写入半字，1111写入完整32位
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            inst_WB <= NOP;
            load_funct3_reg <= 2'd0;                // 针对输入的funct3控制信号，以及计算得到的字节偏移，属于wire信号
            Addr_Byte_low_reg <= 1'd0;              // 而对于DMEM的读取，已经打了一拍输出data_B，即上述两个信号已经落后了一拍
            data_other <= 32'd0;                    // 为保证指令正确执行，需要把控制信号与data_B对齐，才能保证data_B能正确扩展
            sel <= 1'b0;                            // 同时考虑ALU_MA，PC+4信号也落后一拍，也需要打一拍才能对齐进入MUX
        end                                         // 所以通过一级时序逻辑，将所需要的信号打一拍，而后续处理、连接MUX都采用时序逻辑，实现流水线
        else begin
            inst_WB <= inst_MA;
            load_funct3_reg <= load_funct3;         // 保存funct3
            Addr_Byte_low_reg <= Addr_Byte_low;     // 保存字节偏移
            sel <= (data_sel == 2'b00);             // 将3选1MUX拆成两个2选1MUX，寄存器只需要1位保存sel
            case (data_sel)                         // 把其中一个数据打一拍放进寄存器
                2'b01: data_other <= ALU_MA;
                2'b10: data_other <= pc_MA + 32'd4;
                default: data_other <= 32'd0;
            endcase
        end
    end

    load_extend U_load_extend (                     // 数据位扩展模块，按funct3解码，将访存读取的数据按要求扩展至32bit
        .funct3(load_funct3_reg),
        .data_in(data_B),
        .Addr_low(Addr_Byte_low_reg),
        .data_extended(data_extended)
    );

    // data_extended与data_other已经对齐且打了一拍，输出data_WB只需要组合逻辑输出，不能再打一拍
    assign data_WB = sel ? data_extended : data_other;

endmodule
