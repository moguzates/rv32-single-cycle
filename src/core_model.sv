module core_model
    import riscv_pkg::*;
(
    input  logic clk_i,
    input  logic rstn_i,
    input  logic [XLEN-1:0] addr_i,
    output logic            update_o,
    output logic [XLEN-1:0] data_o,
    output logic [XLEN-1:0] pc_o
);

    //Memory
    parameter int MEM_SIZE = 1024;
    logic [31:0] imem [MEM_SIZE-1:0];
    logic [31:0] dmem [MEM_SIZE-1:0];

    //pc + instr
    logic [XLEN-1 : 0] pc_d;
    logic [XLEN-1 : 0] pc_q;
    logic [XLEN-1 : 0] jump_pc_d;
    logic              jump_pc_valid_d;
    logic [XLEN-1 : 0] instr_d;

    always_ff @(posedge clk_i) begin : pc_change_block
        if(~rstn_i) begin
            pc_q <= '0;
        end else begin
            pc_q <= pc_d;
        end
    end

    always_comb begin : pc_change_comb
        pc_d = pc_q;
        if (jump_pc_valid_d) begin
            pc_d = jump_pc_d;
        end else begin
            pc_d = pc_q + 4;
        end
        instr_d = imem[pc_d[$clog2(MEM_SIZE)-1:0]];
    end
/*
    always_comb begin : decode
        case(instr_d[6:0])
            OpcodeLui :
            OpcodeAuipc:
            OpcodeJal : 
            OpcodeJalr :
            OpcodeBranch :
                case(instr_d[14:12])
                    F3_BEQ  :
                    F3_BNE  :
                    F3_BLT  :
                    F3_BGE  :
                    F3_BLTU :
                    F3_BGEU :
                endcase
            OpcodeLoad :
                case(instr_d[14:12])
                    F3_LB  :
                    F3_LH  :
                    F3_LW  :
                    F3_LBU :
                    F3_LHU :
                endcase
            OpcodeStore :
                case(instr_d[14:12])
                    F3_SB :
                    F3_SH :
                    F3_SW :
                endcase
            OpcodeOpImm :
                case(instr_d[14:12])
                    F3_ADDI  : 
                    F3_SLTI  : 
                    F3_SLTIU : 
                    F3_XORI  : 
                    F3_ORI   : 
                    F3_ANDI  : 
                    F3_SLLI  :
                        if(instr_d[31:25] == F7_SLLI) begin
                        end
                    F3_SRLI  : 
                        if(instr_d[31:25] == F7_SRLI) begin
                        end
                    F3_SRAI  : 
                        if(instr_d[31:25] == F7_SRAI) begin
                        end
                endcase
            OpcodeOp :
                case(instr_d[14:12])
                    F3_ADD  :
                        if(instr_d[31:25] == F7_ADD)
                    F3_SUB  :
                        if(instr_d[31:25] == F7_SUB)
                    F3_SLL  :
                        if(instr_d[31:25] == F7_SLL)
                    F3_SLT  :
                        if(instr_d[31:25] == F7_SLT)
                    F3_SLTU :
                        if(instr_d[31:25] == F7_SLTU)
                    F3_XOR  :
                        if(instr_d[31:25] == F7_XOR)
                    F3_SRL  :
                        if(instr_d[31:25] == F7_SRL)
                    F3_SRA  :
                        if(instr_d[31:25] == F7_SRA)
                    F3_OR   :
                        if(instr_d[31:25] == )F7_OR
                    F3_AND  :
                        if(instr_d[31:25] == F7_AND)
                endcase

        endcase
    end
*/

endmodule
