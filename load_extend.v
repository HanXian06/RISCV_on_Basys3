`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/27 20:43:14
// Design Name: 
// Module Name: load_extend
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


module load_extend(
    input [2:0] funct3,
    input [31:0] data_in,
    input [1:0] Addr_low,
    output reg [31:0] data_extended
    );

    wire [31:0] data_temp;

    assign data_temp = data_in >> {Addr_low, 3'b000};
    
    always @(*) begin
        case (funct3)
            3'b000: data_extended = {{24{data_temp[7]}}, data_temp[7:0]};
            3'b001: data_extended = {{16{data_temp[15]}}, data_temp[15:0]};
            3'b010: data_extended = data_temp;
            3'b100: data_extended = {24'd0, data_temp[7:0]};
            3'b101: data_extended = {16'd0, data_temp[15:0]};
            default: data_extended = 32'd0;
        endcase
    end  

endmodule
