`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/25 19:12:46
// Design Name: 
// Module Name: decoder
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


module decoder(
    input clk,
    input reset,
    input brench_com_equ,                       //brench compare equal;     0:unequal/equality check module is not enabled; 1:equal
    input brench_com_sma,                       //brench compare smaller;   0:rs1>=rs2/smaller check module is not enabled; 2:rs1<rs2
    input [31:0]inst_id,
    output reg [31:0] inst_ex,
    output reg [31:0] inst_ma,
    output reg [31:0] inst_wb,

    //if level
    output adv_address_sel,                     //jump target,pc + 4,select;0:pc + 4;1:jump target
    
    //id level
    output data_wr_en,                          //reg write enable;0:disable;1:enable
    //actually data_wr_en is wb level signal
    output address_a_sel,                       //0:address from instruction; 1:address is 00000
    output adv_load_a_sel,                      //load data adventure,data a,select; 0:data a; 1:load data adventure
    output adv_load_b_sel,                      //load data adventure,data b,select; 0:data b; 1:load data adventure
    
    //ex level
    output com_sig,                             //compare(sign or unsign); 0:sign; 1:unsign
    output equ_sma,                             //compare(equal or smaller); 0:equal; 1:smaller
    output [1:0] dataa_address_adv1_adv2_sel,
    //data a,pc(Instruction address),Level 1 data Adventure,Level 2 data Adventure,select;
    //00,01,10,11=data a,pc,Level 1 data Adventure,Level 2 data Adventure
    output [1:0] datab_adv1_adv2_sel,
    //data b,Level 1 data Adventure,Level 2 data Adventure,select;
    //00,01,10,11=data b,data b,Level 1 data Adventure,Level 2 data Adventure
    output datab_imm_sel,                       //data b,immediate value,select; 0:data b; 1: imm
    output [4:0] imm_sort,                      //immediate value sort;one hot
    //[4:0]=j,u,b,s,i
    output [9:0] alu_sort,                      //alu sort;one hot
    //[9:0]=and,or,arithmetic right shift,logical right shift,xor,compare(unsign),compare(sign),left shift,minus,add
    
    //ma level
    output [3:0] wr_en,                         //0000:read 0001:byte 0011:half word 1111:word
    output [1:0] datard_dataca_address,         //data read result,data caculate result,pc+4(Instruction address),select
    //00,01,10,11=data read result,data caculate result,pc+4,pc+4
    output [2:0] load_lenth                     //this is load fun3
    );


    //if level
    reg brench_jump_flag;
    always@(*)begin
        if(inst_ex[14]) begin                   //compare smaller
            if(inst_ex[12])begin            //biger?
                if(~brench_com_sma)     //yes
                brench_jump_flag=1;
                else                    //no
                brench_jump_flag=0;
            end
            else begin                      //smaller?
                if(brench_com_sma)      //yes
                brench_jump_flag=1;
                else                    //no
                brench_jump_flag=0;
            end
        end
        else if(~inst_ex[14])begin              //compare equal
            if(inst_ex[12])begin            //unequal?
                if(~brench_com_equ)     //yes
                brench_jump_flag=1;
                else                    //no
                brench_jump_flag=0;
            end
            else begin                      //equal?
                if(brench_com_equ)      //yes
                brench_jump_flag=1;
                else                    //no
                brench_jump_flag=0;
            end
        end
    end
    assign adv_address_sel=inst_ex[6]&(inst_ex[2]|brench_jump_flag);
    //jump+need brench





    //id level
    assign data_wr_en = inst_wb[4]|inst_wb[2]|(~inst_wb[5]);
    //include r_type,i_type,u_type,j_type
    //r,i,s,b,u,j 01100,00100(00000)(11001),01000,11000,01101(00101),11011
    assign address_a_sel = (~inst_id[6])&(inst_id[5])&(inst_id[4])&(~inst_id[3])&(inst_id[2]);
    //only lui need all 0
    wire ex_load_flag;
    wire id_users1_flag;
    wire id_users2_flag;
    wire exrd_match_idrs1;
    wire exrd_match_idrs2;
    assign ex_load_flag=(~inst_ex[6])&(~inst_ex[5])&(~inst_ex[4])&(~inst_ex[3])&(~inst_ex[2]);
    assign id_users1_flag=(~inst_id[2])|((~inst_id[3])&inst_id[6]);
    //u_type,j_type not include
    assign id_users2_flag=(~inst_id[2])|(inst_id[5]);
    //i_type, u_type, j_type not include
    assign exrd_match_idrs1=(inst_ex[11:7]==inst_id[19:15]);
    assign exrd_match_idrs2=(inst_ex[11:7]==inst_id[24:20]);

    assign adv_load_a_sel = ex_load_flag&id_users1_flag&exrd_match_idrs1;
    assign adv_load_b_sel = ex_load_flag&id_users2_flag&exrd_match_idrs2;





    //ex level
    assign com_sig = inst_ex[13];
    assign equ_sma = inst_ex[14];

    wire ma_userd_flag;
    wire wb_userd_flag;
    assign ma_userd_flag = inst_ma[2]|inst_ma[3]|inst_ma[4]|(~inst_ma[5]);
    assign wb_userd_flag = inst_wb[2]|inst_wb[3]|inst_wb[4]|(~inst_wb[5]);
    //use rd reg include 01100,00100,00000,11001,01101,00101,11011

    wire mard_match_exrs1;
    wire wbrd_match_exrs1;
    assign mard_match_exrs1 = (inst_ma[11:7]==inst_ex[19:15]);
    assign wbrd_match_exrs1 = (inst_wb[11:7]==inst_ex[19:15]);

    wire pc_need_flag;
    wire adv1_dataa_flag;
    wire adv2_dataa_flag;


    wire mard_match_exrs2;
    wire wbrd_match_exrs2
    assign mard_match_exrs2 = (inst_ma[11:7]==inst_ex[24:20]);
    assign wbrd_match_exrs2 = (inst_wb[11:7]==inst_ex[24:20]);

    wire imm_need_flag;
    wire adv1_datab_flag;
    wire adv2_datab_flag;

    assign pc_need_flag = ((inst_ex[6])&(inst_ex[5])&(~inst_ex[4])&(inst_ex[3])&(inst_ex[2]))|
    ((~inst_ex[6])&(~inst_ex[5])&(inst_ex[4])&(~inst_ex[3])&(inst_ex[2]))|
    ((inst_ex[6])&(inst_ex[5])&(~inst_ex[4])&(~inst_ex[3])&(~inst_ex[2]));
    //11011,00101,11000 (jal, auipc, brench)
    assign adv1_dataa_flag = ma_userd_flag&mard_match_exrs1;
    assign adv2_dataa_flag = wb_userd_flag&wbrd_match_exrs1;
    assign dataa_address_adv1_adv2_sel = pc_need_flag?(01:(adv1_dataa_flag?10:(adv2_dataa_flag?11:00)))


    assign imm_need_flag = ((inst_ex[6])|(~inst_ex[5])|(~inst_ex[4])|(inst_ex[3])|(inst_ex[2]));
    //only r type don't need imm
    assign adv1_datab_flag = ma_userd_flag&mard_match_exrs2;
    assign adv2_datab_flag = wb_userd_flag&wbrd_match_exrs2;
    assign datab_imm_sel = imm_need_flag;
    assign datab_adv1_adv2_sel = adv1_datab_flag?(10:(adv2_datab_flag?11:01));
    //????????

    assign imm_sort = {
        (inst_ex[6:2]==5'b11011),
        ((inst_ex[6:2]==5'b01101)|(inst_ex[6:2]==5'b00101)),
        (inst_ex[6:2]==5'b11000),
        ((inst_ex[6:2]==5'b00100)|(inst_ex[6:2]==5'b00000)|(inst_ex[6:2]==5'b11001)),
        (inst_ex[6:2]==5'b01100)
    };


    wire r_flag;
    wire i_flag;
    assign r_flag=(inst_ex[6:2]==5'b01100);
    assign i_flag=(inst_ex[6:2]==5'b00100);
    assign alu_sort = {
        ((r_flag|i_flag)&(inst_ex[14:12]==3'b111)),
        ((r_flag|i_flag)&(inst_ex[14:12]==3'b110)),
        ((r_flag|i_flag)&(inst_ex[14:12]==3'b101)&(inst_ex[30])),
        ((r_flag|i_flag)&(inst_ex[14:12]==3'b101)&(~inst_ex[30])),
        ((r_flag|i_flag)&(inst_ex[14:12]==3'b100)),
        ((r_flag|i_flag)&(inst_ex[14:12]==3'b011)),
        ((r_flag|i_flag)&(inst_ex[14:12]==3'b010)),
        ((r_flag|i_flag)&(inst_ex[14:12]==3'b001)),
        ((r_flag)&(inst_ex[14:12]==3'b000)&(inst_ex[30])),
        (|alu_sort[9:1]),
    }
    //[9:0]=and,or,arithmetic right shift,logical right shift,xor,compare(unsign),compare(sign),left shift,minus,add




    //ma
    wire storage_flag;
    wire load_flag;
    wire jump_flag;
    assign storage_flag = (inst_ma[6:2]==5'b01000);
    assign load_flag = (inst_ma[6:2]==5'b00000);
    assign jump_flag = ({inst_ma[6:4],inst_ma[2]}==4'b1101);

    assign wr_en = storage_flag?(inst_ma[13]?4'b1111:(inst_ma[12]?4'b0011:4'b0001)):4'b0000;

    assign datard_dataca_address = load_flag?2'b00:(jump_flag?2'b10:2'b01);

    assign load_lenth = inst_ma[14:12];

endmodule
