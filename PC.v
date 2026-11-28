`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/25 13:41:35
// Design Name: 
// Module Name: PC
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


module PC(
    input clk,
    input rst,
    input [31:0] load_addr,     // PC加载跳转的地址
    input load,                 // PC加载使能
    input en,                   // PC递增使能
    output [9:0] inst_addr,     // 按字访问，深度1024，字长32
    output reg [31:0] pc_reg    // 考虑auipc、jal需要计算，此时PC输出需要为32位
    );

    wire [31:0] addr;
    // 此处为适应jalr指令，直接将地址的最低位强制置0；而对于PC加载的指令，地址一定是4的倍数，所以强制置0不会对其他指令有影响。
    assign addr = {load_addr[31:1], 1'b0};
    assign inst_addr = pc_reg[11:2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg <= 32'd0;    // 复位
        end
        else begin
            if (load) begin     // 加载外部输入
                pc_reg <= addr;
            end
            else if (en) begin  // PC + 4正常计数
                pc_reg <= pc_reg + 32'd4;
            end
            else begin          // PC保持，不计数
                pc_reg <= pc_reg;
            end
        end
    end

endmodule
