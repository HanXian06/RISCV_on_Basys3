module EX(
    input clk, rst,
    input [31:0] Data_A, Data_B_EX,Data_MEM,
    input [31:0] PC_EX,
    input [31:7] inst,
    input [4:0] sel_ImmGen_EX,
    input BrUn_EX,
    input [1:0] sel_A_EX, sel_B_EX,
    input datab_imm_sel,
    input [9:0] sel_ALU_EX,
    input [31:0] ALU_in, // .ALU_in(ALU_out)
    output wire BrEq, BrLT,
    output reg [31:0] ALU_out,
    output wire [31:0] ALU_out_logic,
    output reg [31:0] Data_B_MA,
    output reg [31:0] PC_MA
);
wire [31:0] imm;
ImmGen uut(
    .inst(inst),
    .sel_ImmGen_EX(sel_ImmGen_EX),
    .imm(imm)
);
BranchCamp uut1(
    .Data_A(Data_A),
    .Data_B(Data_B_EX),
    .BrUn_EX(BrUn_EX),
    .BrEq(BrEq),
    .BrLT(BrLT)
);
wire [31:0] dataA_ALU, dataB_ALU_pre,dataB_ALU;
mux4_1 uut2(
    .Data(Data_A),
    .PC_data(PC_EX),
    .ALU(ALU_in),
    .DMEM(Data_MEM),
    .sel_EX(sel_A_EX),
    .data_ALU(dataA_ALU)
);
mux4_1 uut3(
    .Data(Data_B_EX),
    .PC_data(Data_B_EX),
    .ALU(ALU_in),
    .DMEM(Data_MEM),
    .sel_EX(sel_B_EX),
    .data_ALU(dataB_ALU_pre)
);
//mux2_1
assign dataB_ALU = datab_imm_sel ? imm : dataB_ALU_pre;
ALU uut4(
    .dataA(dataA_ALU),
    .dataB(dataB_ALU),
    .sel_ALU_EX(sel_ALU_EX),
    .ALU_out_logic(ALU_out_logic)
);
// three resigters for pipelining
always@(posedge clk or posedge rst)begin
    if(rst) ALU_out <= 32'd0;
    else ALU_out <= ALU_out_logic;
end
always@(posedge clk or posedge rst)begin
    if(rst) PC_MA <= 32'd0;
    else PC_MA <= PC_EX;
end
always@(posedge clk or posedge rst)begin
    if(rst) Data_B_MA <= 32'd0;
    else Data_B_MA <= dataB_ALU_pre;
end
endmodule

module ImmGen(
    input [31:7] inst,
    input [4:0] sel_ImmGen_EX,
    output wire [31:0] imm
);
localparam j=5'b10000, u=5'b01000, b=5'b00100, s=5'b00010, i=5'b00001;
//remain to be optimized
wire [31:0] imm_j = {{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0};
wire [31:0] imm_u = {inst[31:12],12'd0};
wire [31:0] imm_b = {{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0};
wire [31:0] imm_s = {{21{inst[31]}},inst[30:25],inst[11:8],inst[7]};
wire [31:0] imm_i = {{21{inst[31]}},inst[30:25],inst[24:21],inst[20]};
assign imm = (imm_j & {32{sel_ImmGen_EX[4]}}) |
             (imm_u & {32{sel_ImmGen_EX[3]}}) |
             (imm_b & {32{sel_ImmGen_EX[2]}}) |
             (imm_s & {32{sel_ImmGen_EX[1]}}) |
             (imm_i & {32{sel_ImmGen_EX[0]}});
endmodule

module BranchCamp(
    input [31:0] Data_A, Data_B,
    input BrUn_EX,
    output reg BrEq, BrLT
);
//remain to be optimized
localparam  sign=1'b0, equal=1'b0;
always@(*)begin
    BrEq = (Data_A==Data_B);
    if(BrUn_EX!=sign) BrLT = (Data_A<Data_B);
    else BrLT = (Data_A[31]&(!Data_B[31]))|((Data_A[31]==Data_B[31])&&(Data_A[30:0]<Data_B[30:0]));
end
endmodule

module mux4_1(
    input [31:0] Data, PC_data, ALU, DMEM,
    input [1:0] sel_EX,
    output reg [31:0] data_ALU
);
//remain to be optimized
localparam sel_data=2'b00,sel_PC_imm=2'b01,sel_ALU=2'b10,sel_DMEM=2'b11;
always@(*)begin
    case(sel_EX)
    sel_data:data_ALU=Data;
    sel_PC_imm:data_ALU=PC_data;
    sel_ALU:data_ALU=ALU;
    sel_DMEM:data_ALU=DMEM;
    default:data_ALU=32'd0;
    endcase
end
endmodule

module ALU(
    input [31:0] dataA, dataB,
    input [9:0] sel_ALU_EX,
    output reg [31:0] ALU_out_logic
);
//remain to be optimized
localparam sel_and=10'b1000000000,sel_or=10'b0100000000,sel_sra=10'b0010000000,sel_srl=10'b0001000000,sel_xor=10'b0000100000,sel_sltu=10'b0000010000,sel_slt=10'b0000001000,sel_sll=10'b0000000100,sel_sub=10'b0000000010,sel_add=10'b0000000001;
reg [31:0] ALU_out_logic_pre;
reg [32:0] sub_pre;
always@(*)begin
    case(sel_ALU_EX)
    sel_and:ALU_out_logic=dataA&dataB;
    sel_or:ALU_out_logic=dataA|dataB;
    sel_xor:ALU_out_logic=dataA^dataB;
    sel_sll:begin
        ALU_out_logic_pre=dataA<<{dataB[4:3],3'b000};
        ALU_out_logic=ALU_out_logic_pre<<dataB[2:0];
    end
    sel_srl:begin
        ALU_out_logic_pre=dataA>>{dataB[4:3],3'b000};
        ALU_out_logic=ALU_out_logic_pre>>dataB[2:0];
    end
    sel_sra:begin
        ALU_out_logic_pre=$signed(dataA)>>>{dataB[4:3],3'b000};
        ALU_out_logic=$signed(ALU_out_logic_pre)>>>dataB[2:0];
    end
    sel_sltu:begin
        sub_pre={1'b0,dataA}-{1'b0,dataB};
        ALU_out_logic={31'd0,sub_pre[32]};
    end
    sel_slt:begin
        sub_pre={1'b0,dataA}-{1'b0,dataB};
        ALU_out_logic=(dataA[31]^dataB[31])?{31'd0, dataA[31]}:{31'd0,sub_pre[32]};
    end
    sel_sub:begin
        sub_pre={1'b0,dataA}-{1'b0,dataB};
        ALU_out_logic=sub_pre[31:0];
    end
    sel_add:ALU_out_logic=dataA+dataB;
    default:begin
        ALU_out_logic=32'd0;
        ALU_out_logic_pre=32'd0;
    end
    endcase
end
endmodule