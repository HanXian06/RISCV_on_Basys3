`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/25 18:56:40
// Design Name: 
// Module Name: rst_sync
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


module rst_sync(            // 异步输入，同步释放
    input clk,
    input rst_in,
    output reg rst_out
    );
    reg rst_temp;

    always @(posedge clk or posedge rst_in) begin
        if (rst_in) begin
            rst_temp <= 1'b1;
            rst_out <= 1'b1;
        end
        else begin
            rst_temp <= 1'b0;
            rst_out <= rst_temp;
        end
    end
endmodule
