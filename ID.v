`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/25 18:55:35
// Design Name: 
// Module Name: ID
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


module ID(
    input clk,
    input rst,
    // ID输入信号
    input [31:0] inst_ID,                       // IF -> ID 流水线寄存器
    input [31:0] pc_ID,                         // IF -> ID 流水线寄存器
    input [31:0] inst_WB,                       // WB -> ID 流水线寄存器
    input [31:0] data_WB,                       // WB -> ID 流水线寄存器
    // 组合逻辑控制信号
    input shortcut_call,                        // 捷径加载使能，流水线寄存器直接从data_WB读取数据，节省一个周期
    input rs1_shortcut_en,                      // rs1_EX捷径加载使能
    input rs2_shortcut_en,                      // rs2_EX捷径加载使能
    input NOP_call,                             // NOP信号拉高则本周期Inst输出NOP，等价于清空当前指令输出
    input writeback_en,                         // WB写回使能，拉高则允许写入寄存器
    input x0_call,                              // 针对lui指令，立即数生成后经过ALU不需要进行计算，此时x0_call将Addr_A读为x0
    // ID输出信号
    output reg [31:0] pc_EX,                    // ID -> EX 流水线寄存器
    output [31:0] rs1_EX,                       // ID -> EX 流水线寄存器
    output [31:0] rs2_EX,                       // ID -> EX 流水线寄存器
    output reg [31:0] inst_EX                   // ID -> EX 流水线寄存器
    );

    reg [31:0] rs1_data, rs2_data;
    reg [31:0] register [0:31];
    wire [4:0] rs1_addr, rs2_addr, rd_addr;

    localparam NOP = 32'h0000_0013;

    assign rs1_addr = x0_call ? 5'd0 : inst_ID[19:15];              // rs1对应寄存器所在地址（x0_call则读取x0）
    assign rs2_addr = inst_ID[24:20];                               // rs2对应寄存器所在地址
    assign rd_addr = inst_WB[11:7];                                 // rd 对应寄存器所在地址

    always @(posedge clk or posedge rst) begin  // PC，Inst寄存器直接打一拍，但Inst需要考虑是否需要NOP
        if (rst) begin
            pc_EX <= 32'd0;
            inst_EX <= NOP;
        end
        else begin
            pc_EX <= pc_ID;
            inst_EX <= NOP_call ? NOP : inst_ID;// Inst寄存器注入NOP
        end
    end

    assign rs1_EX = rs1_data;                   // rs1_data和rs2_data已经是寄存器了
    assign rs2_EX = rs2_data;                   // 所以rs1_EX，rs2_EX只需要assign输出，不能再多打一拍

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rs1_data <= 32'd0;
            rs2_data <= 32'd0;
            for (i = 0; i < 32; i = i + 1) begin
                register[i] <= 32'd0;
            end   
        end
        else begin                              // 如果读取地址指向x0，则直接输出0，防止x0数据已被错误覆盖
            rs1_data <= (rs1_addr == 5'd0) ? 32'd0 : register[rs1_addr];
            rs2_data <= (rs2_addr == 5'd0) ? 32'd0 : register[rs2_addr];

            if (writeback_en) begin             // 如果写入地址指向x0，则直接写入0，防止错误覆盖x0
                register[rd_addr] <= (rd_addr == 5'd0) ? 32'd0 : data_WB;
            end
            if (shortcut_call) begin            // 这里不用else-if，因为捷径不影响正常写入，只是当前读取提前
                if (rs1_shortcut_en) begin      // 如果读取地址指向x0，则直接输出0，防止x0数据已被错误覆盖
                    rs1_data <= (rd_addr == 5'd0) ? 32'd0 : data_WB;
                end
                if (rs2_shortcut_en) begin
                    rs2_data <= (rd_addr == 5'd0) ? 32'd0 : data_WB;
                end
            end
        end
    end
    
endmodule
