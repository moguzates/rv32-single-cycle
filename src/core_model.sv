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
    logic [31:0]       imem [MEM_SIZE-1:0];
    logic [31:0]       dmem [MEM_SIZE-1:0];
    logic [XLEN-1 : 0] rf   [31:0]; //register file

    //pc + instr
    logic [XLEN-1 : 0] pc_d;
    logic [XLEN-1 : 0] pc_q;
    logic [XLEN-1 : 0] jump_pc_d;
    logic              jump_pc_valid_d;
    logic [XLEN-1 : 0] instr_d;

    logic [XLEN-1 : 0] rs1_data;
    logic [XLEN-1 : 0] rs2_data;
    logic [XLEN-1 : 0] imm_data;
    logic [4:0]        shamt;
    logic [XLEN-1 : 0] rd_data; //register destination

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

    always_comb begin : decode
        case(instr_d[6:0])
            OpcodeLui :   imm_data = {instr_d[31:12] , 12'b0};
            OpcodeAuipc : imm_data = {instr_d[31:12] , 12'b0};
            OpcodeJal :   imm_data = {{12'({instr_d[31]})}, instr_d[19:12], instr_d[20], instr_d[30:21], 1'b0};             
            OpcodeJalr : begin
                if(instr_d[14:12] == F3_JALR) begin
                    rs1_data = rf[instr_d[19:15]]; 
                    imm_data = {{21'({instr_d[31]})}, instr_d[30:20]};  
                end           
            end
            OpcodeBranch : begin
                if (instr_d[14:12] inside {F3_BEQ, F3_BNE, F3_BLT, F3_BGE, F3_BLTU, F3_BGEU}) begin
                    rs1_data = rf[instr_d[19:15]]; 
                    rs2_data = rf[instr_d[24:20]];
                    imm_data = {{18'({instr_d[31]})}, instr_d[31], instr_d[7], instr_d[10:5], instr_d[11:7], 1'b0};
                end
            end
            OpcodeLoad : begin
                rs1_data = rf[instr_d[19:15]];
                imm_data = {{20'({instr_d[31]})}, instr_d[31:20]};
            end
            OpcodeStore : begin
                rs1_data = rf[instr_d[19:15]]; 
                rs2_data = rf[instr_d[24:20]];
                imm_data = {{20'({instr_d[31]})}, instr_d[31:25], instr_d[11:7]};
            end
            OpcodeOpImm : begin
                case(instr_d[14:12])
                    F3_ADDI, F3_SLTI, F3_SLTIU, F3_XORI, F3_ORI, F3_ANDI : begin
                        rs1_data = rf[instr_d[19:15]];
                        imm_data = {{20'({instr_d[31]})}, instr_d[31:20]};
                    end
                    F3_SLLI :
                        if(instr_d[31:25] == F7_SLLI) begin
                            shamt = instr_d[24:20];
                            rs1_data = rf[instr_d[19:15]];
                        end
                    F3_SRLI : 
                        if(instr_d[31:25] inside {F7_SRLI, F7_SRAI}) begin
                            shamt = instr_d[24:20];
                            rs1_data = rf[instr_d[19:15]];
                        end
                endcase
            end
            OpcodeOp :
                case(instr_d[14:12])
                    F3_ADD :
                        if(instr_d[31:25] inside {F7_ADD, F7_SUB}) begin
                            rs1_data = rf[instr_d[19:15]];
                            rs2_data = rf[instr_d[24:20]];        
                        end 
                    F3_SLL  :
                        if(instr_d[31:25] == F7_SLL) begin
                            rs1_data = rf[instr_d[19:15]];
                            rs2_data = rf[instr_d[24:20]];        
                        end
                    F3_SLT  :
                        if(instr_d[31:25] == F7_SLT) begin
                            rs1_data = rf[instr_d[19:15]];
                            rs2_data = rf[instr_d[24:20]];        
                        end
                    F3_SLTU :
                        if(instr_d[31:25] == F7_SLTU) begin
                            rs1_data = rf[instr_d[19:15]];
                            rs2_data = rf[instr_d[24:20]];        
                        end
                    F3_XOR  :
                        if(instr_d[31:25] == F7_XOR) begin
                            rs1_data = rf[instr_d[19:15]];
                            rs2_data = rf[instr_d[24:20]];        
                        end
                    F3_SRL  :
                        if(instr_d[31:25] inside {F7_SRL, F7_SRA}) begin
                            rs1_data = rf[instr_d[19:15]];
                            rs2_data = rf[instr_d[24:20]];        
                        end
                    F3_OR   :
                        if(instr_d[31:25] == F7_OR) begin
                            rs1_data =rf[instr_d[19:15]];
                            rs2_data =rf[instr_d[24:20]];        
                        end
                    F3_AND  :
                        if(instr_d[31:25] == F7_AND) begin
                            rs1_data =rf[instr_d[19:15]];
                            rs2_data =rf[instr_d[24:20]];        
                        end
                endcase
                default : ;
        endcase
    end

endmodule
