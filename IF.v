`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/25 15:02:28
// Design Name: 
// Module Name: IF
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


module IF(
    input clk,
    input rst,
    // IF输入信号
    input [31:0] ALU_shortcut,      // 捷径加载输入
    // 组合逻辑控制信号
    input load_control,             // PC加载信号，拉高则PC加载ALU_MA寄存器输出
    input stop_call,                // 留存信号，拉高则PC不递增也不加载，PC_ID输出也不更新，保持当前IF区工作状态
    input NOP_call,                 // NOP信号，拉高则本周期Inst输出NOP，等价于清空当前指令输出
    // 写入IMEM信号
    input wea,                      // 写使能
    input [31:0] write_inst,        // 写入指令
    input [9:0] write_addr,         // 写入地址
    // IF输出信号   
    output reg [31:0] pc_ID,        // IF -> ID 流水线寄存器
    output [31:0] inst_ID           // IF -> ID 流水线寄存器
    );

    localparam NOP = 32'h0000_0013; // addi x0 x0 0，用于清空当前指令

    wire load;
    wire [9:0] inst_addr;
    wire [31:0] inst_temp;
    wire enb;
    wire [31:0] pc_reg;
    wire [31:0] load_addr;
    reg NOP_reg;

    // 整体控制信号写入优先(wea使能时不拉高)
    assign load = load_control & ~wea;                          // 加载信号
    assign enb = ~rst & ~wea & ~stop_call;                      // IMEM读取使能
    assign load_addr = ALU_shortcut;                            // PC加载shortcut，直接在EX阶段确认跳转

    // 调用BRAM IP生成IMEM（深度1024）
    IMEM_1024B U_IMEM (
        .clka(clk),
        .addra(write_addr),
        .ena(wea),
        .wea(wea),
        .dina(write_inst),

        .clkb(clk),
        .addrb(inst_addr),
        .enb(enb),
        .doutb(inst_temp)
    );

    // 调用PC
    PC U_PC (
        .clk(clk),
        .rst(rst),
        .load_addr(load_addr),
        .load(load),
        .en(enb),
        .inst_addr(inst_addr),
        .pc_reg(pc_reg)
    );

    // 多打一拍，将PC结果存入pc_ID
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_ID <= 32'd0;
        end
        else if(enb) begin
            pc_ID <= pc_reg;
        end
        else begin
            pc_ID <= pc_ID;
        end
    end

    // 更新NOP_reg（时序更新防止NOP_call拉低后，inst_ID读取inst_temp的无效值；NOP_reg同步更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            NOP_reg <= 1'b1;
        end
        else if (NOP_call) begin    // else-if能确保NOP优先级高于正常IMEM读取
            NOP_reg <= 1'b1;
        end
        else if (enb) begin         // 如果没有NOP且IMEM正常读取，把NOP_reg拉低
            NOP_reg <= 1'b0;
        end
        else begin
            NOP_reg <= NOP_reg;
        end
    end

    // 由于IMEM自带打一拍，inst_ID只需考虑是否注入NOP，或者直接读取IMEM的结果
    assign inst_ID = NOP_reg ? NOP : inst_temp;

endmodule
