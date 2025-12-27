module core_model
    import riscv_pkg::*;
(
    input  logic clk_i,
    input  logic rstn_i,
    input  logic [XLEN-1:0] addr_i,
    output logic            update_o,
    output logic [XLEN-1:0] data_o,
    output logic [XLEN-1:0] pc_o,
    output logic [XLEN-1:0] instr_o,
    output logic [     4:0] reg_addr_o,
    output logic [XLEN-1:0] reg_data_o
);

    //Memory
    parameter int MEM_SIZE = 2048;
    logic [31:0]       imem [MEM_SIZE-1:0];
    logic [31:0]       dmem [MEM_SIZE-1:0];
    logic [XLEN-1 : 0] rf   [31:0]; //register file
    initial $readmemh("./test/test.hex", imem, 0, MEM_SIZE); //read the txt and give to the imem register

    //pc + instr
    logic [XLEN-1 : 0] pc_d;
    logic [XLEN-1 : 0] pc_q;
    logic [XLEN-1 : 0] jump_pc_d;
    logic              jump_pc_valid_d;
    logic [XLEN-1 : 0] instr_d;

    assign pc_o = pc_q;
    assign data_o = dmem[addr_i];
    assign instr_o = instr_d;
    assign reg_addr_o = rf_wr_enable ? instr_d[11:7] : '0;
    assign reg_data_o = rd_data;

    logic [XLEN-1 : 0] rs1_data;     // source register 1 data        
    logic [XLEN-1 : 0] rs2_data;     // source register 2 data
    logic [XLEN-1 : 0] imm_data;     // immediate data
    logic [       4:0] shamt_data;
    logic [XLEN-1 : 0] rd_data;      // register destination
    logic              rf_wr_enable; // register file write enable
    logic [XLEN-1 : 0] mem_wr_data;      // register destination
    logic [XLEN-1 : 0] mem_wr_addr; // memory write address
    logic              mem_wr_enable; // register file write enable 
    
    always_ff @(posedge clk_i) begin : pc_change
        if(~rstn_i) begin
            pc_q <= 'h8000_0000;
            update_o <= '0;
        end else begin
            update_o <= '1;
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
        instr_d = imem[pc_q[$clog2(MEM_SIZE*4)-1:2]];
    end

    always_comb begin : decode
        imm_data   = 32'b0;
        shamt_data = 5'b0; 
        rs1_data   = 32'b0;
        rs2_data   = 32'b0;

        case(instr_d[6:0])
            OpcodeLui :   imm_data = {instr_d[31:12] , 12'b0};
            OpcodeAuipc : imm_data = {instr_d[31:12] , 12'b0};
            OpcodeJal :   imm_data = {{12'(signed'({instr_d[31]}))}, instr_d[19:12], instr_d[20], instr_d[30:21], 1'b0};             
            OpcodeJalr : begin
                if(instr_d[14:12] == F3_JALR) begin
                    rs1_data = rf[instr_d[19:15]]; 
                    imm_data = {{21'(signed'({instr_d[31]}))}, instr_d[30:20]};  
                end           
            end
            OpcodeBranch : begin
                if (instr_d[14:12] inside {F3_BEQ, F3_BNE, F3_BLT, F3_BGE, F3_BLTU, F3_BGEU}) begin
                    rs1_data = rf[instr_d[19:15]]; 
                    rs2_data = rf[instr_d[24:20]];
                    imm_data = {{19'(signed'({instr_d[31]}))}, instr_d[31], instr_d[7], instr_d[30:25], instr_d[11:8], 1'b0};
                end
            end
            OpcodeLoad : begin
                rs1_data = rf[instr_d[19:15]];
                imm_data = {{20'(signed'(instr_d[31]))}, instr_d[31:20]};
            end
            OpcodeStore : begin
                rs1_data = rf[instr_d[19:15]]; 
                rs2_data = rf[instr_d[24:20]];
                imm_data = {{20'(signed'(instr_d[31]))}, instr_d[31:25], instr_d[11:7]};
            end
            OpcodeOpImm : begin
                case(instr_d[14:12])
                    F3_ADDI, F3_SLTI, F3_SLTIU, F3_XORI, F3_ORI, F3_ANDI : begin
                        rs1_data = rf[instr_d[19:15]];
                        imm_data = {{20'(signed'(instr_d[31]))}, instr_d[31:20]};
                    end
                    F3_SLLI :
                        if(instr_d[31:25] == F7_SLLI) begin
                            shamt_data = instr_d[24:20];
                            rs1_data = rf[instr_d[19:15]];
                        end
                    F3_SRLI : 
                        if(instr_d[31:25] inside {F7_SRLI, F7_SRAI}) begin
                            shamt_data = instr_d[24:20];
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

    always_comb begin : execute
        jump_pc_valid_d = 0;
        jump_pc_d = 0; 
        rd_data = 0;
        rf_wr_enable = 0;
        mem_wr_enable = 0;
        mem_wr_data = 0;
        mem_wr_addr = 0;

        case(instr_d[6:0])
            OpcodeLui : begin
                rd_data = imm_data;
                rf_wr_enable = 1'b1;
            end
            OpcodeAuipc: begin
                rd_data = imm_data + pc_q;
                rf_wr_enable = 1'b1;
            end
            OpcodeJal : begin
                jump_pc_valid_d = 1'b1;
                jump_pc_d =  imm_data + pc_q;
                rd_data = pc_q + 4;
                rf_wr_enable = 1'b1;
            end
            OpcodeJalr : begin
                jump_pc_valid_d = 1'b1;
                jump_pc_d =  imm_data + rs1_data;
                rd_data = pc_q + 4; 
            end
            OpcodeBranch :
                case(instr_d[14:12])
                    F3_BEQ  : if (rs1_data == rs2_data) begin
                        jump_pc_d = imm_data + pc_q;
                        jump_pc_valid_d = 1'b1;
                    end
                    F3_BNE  : if (rs1_data != rs2_data) begin
                        jump_pc_d = imm_data + pc_q;
                        jump_pc_valid_d = 1'b1;
                    end
                    F3_BLT  : if ($signed(rs1_data) < $signed(rs2_data)) begin
                        jump_pc_d = imm_data + pc_q;
                        jump_pc_valid_d = 1'b1;
                    end
                    F3_BGE  : if ($signed(rs1_data) >= $signed(rs2_data)) begin
                        jump_pc_d = imm_data + pc_q;
                        jump_pc_valid_d = 1'b1;
                    end
                    F3_BLTU : if (rs1_data < rs2_data) begin
                        jump_pc_d = imm_data + pc_q;
                        jump_pc_valid_d = 1'b1;
                    end
                    F3_BGEU : if (rs1_data >= rs2_data) begin
                        jump_pc_d = imm_data + pc_q;
                        jump_pc_valid_d = 1'b1;
                    end
                endcase
            OpcodeLoad :
                case(instr_d[14:12])
                    F3_LB  : begin
                        rd_data = {{24'({dmem[rs1_data[$clog2(MEM_SIZE)-1 : 0]][7]})}, dmem[rs1_data[$clog2(MEM_SIZE)-1 : 0]][7:0]}; 
                        rf_wr_enable = 1;
                    end
                    F3_LH  : begin
                        rd_data = {{24'({dmem[rs1_data[$clog2(MEM_SIZE)-1 : 0]][7]})}, dmem[rs1_data[$clog2(MEM_SIZE)-1 : 0]][7:0]}; 
                        rf_wr_enable = 1;
                    end
                    F3_LW  : begin
                        rd_data = dmem[rs1_data[$clog2(MEM_SIZE)-1 : 0]]; 
                        rf_wr_enable = 1;
                    end
                    F3_LBU : begin
                        rd_data = {{24'b0}, dmem[rs1_data[$clog2(MEM_SIZE)-1 : 0]][7:0]};
                        rf_wr_enable = 1;
                    end
                    F3_LHU : begin
                        rd_data = {{16'b0}, dmem[rs1_data[$clog2(MEM_SIZE)-1 : 0]][15:0]};
                        rf_wr_enable = 1;
                    end
                endcase
            OpcodeStore :
                case(instr_d[14:12])
                    F3_SB : begin
                        mem_wr_enable = 1'b1;
                        mem_wr_data = rs2_data;
                        mem_wr_addr = rs1_data + imm_data;
                    end
                    F3_SH : begin
                        mem_wr_enable = 1'b1;
                        mem_wr_data = rs2_data;
                        mem_wr_addr = rs1_data + imm_data;
                    end
                    F3_SW : begin
                        mem_wr_enable = 1'b1;
                        mem_wr_data = rs2_data;
                        mem_wr_addr = rs1_data + imm_data;
                    end
                endcase
            OpcodeOpImm :
                case(instr_d[14:12])
                    F3_ADDI  : begin
                        rf_wr_enable = 1'b1;
                        rd_data = $signed(imm_data) + $signed(rs1_data);
                    end
                    F3_SLTI  : begin
                        rf_wr_enable = 1'b1;
                        if($signed(rs1_data) < $signed(imm_data)) rd_data = 32'b1;
                    end
                    F3_SLTIU : begin
                        rf_wr_enable = 1'b1;
                        if(rs1_data < imm_data) rd_data = 32'b1;
                    end
                    F3_XORI  : begin
                        rf_wr_enable = 1'b1;
                        rd_data = rs1_data ^ imm_data;
                    end
                    F3_ORI   : begin
                        rf_wr_enable = 1'b1;
                        rd_data = rs1_data | imm_data;
                    end
                    F3_ANDI  : begin
                        rf_wr_enable = 1'b1;
                        rd_data = rs1_data & imm_data;
                    end 
                    F3_SLLI  :
                        if(instr_d[31:25] == F7_SLLI) begin
                            rf_wr_enable = 1'b1;
                            rd_data = rs1_data << shamt_data;
                        end
                    F3_SRLI  : begin
                        if(instr_d[31:25] == F7_SRLI) begin
                            rf_wr_enable = 1'b1;
                            rd_data = rs1_data >> shamt_data;
                        end else if(instr_d[31:25] == F7_SRAI) begin
                            rf_wr_enable = 1'b1;
                            rd_data = rs1_data >>> shamt_data;
                        end
                    end
                endcase
            OpcodeOp :
                case(instr_d[14:12])
                    F3_ADD  :
                        if(instr_d[31:25] == F7_ADD) begin
                            rf_wr_enable = 1'b1;
                            rd_data = rs1_data + rs2_data;
                        end else if(instr_d[31:25] == F7_SUB) begin
                            rf_wr_enable = 1'b1;
                            rd_data = rs1_data - rs2_data;
                        end
                    F3_SLL  :
                        if(instr_d[31:25] == F7_SLL) begin
                            rf_wr_enable = 1'b1;
                            rd_data = rs1_data << rs2_data;
                        end
                    F3_SLT  :
                        if(instr_d[31:25] == F7_SLT) begin
                            rf_wr_enable = 1'b1;
                            if ($signed(rs1_data) < $signed(rs2_data)) rd_data = 32'b1;
                        end
                    F3_SLTU :
                        if(instr_d[31:25] == F7_SLTU) begin
                            rf_wr_enable = 1'b1;
                            if (rs1_data < rs2_data) rd_data = 32'b1;
                        end
                    F3_XOR  :
                        if(instr_d[31:25] == F7_XOR) begin
                            rf_wr_enable = 1'b1; 
                            rd_data = rs1_data ^ rs2_data;
                        end
                    F3_SRL  :
                        if(instr_d[31:25] == F7_SRL) begin
                            rf_wr_enable = 1'b1; 
                            rd_data = rs1_data >> rs2_data;
                        end else if(instr_d[31:25] == F7_SRA) begin
                            rf_wr_enable = 1'b1; 
                            rd_data = $signed(rs1_data) >>> rs2_data;
                        end
                    F3_OR   :
                        if(instr_d[31:25] == F7_OR) begin
                            rf_wr_enable = 1'b1; 
                            rd_data = rs1_data | rs2_data;
                        end
                    F3_AND  :
                        if(instr_d[31:25] == F7_AND) begin
                            rf_wr_enable = 1'b1; 
                            rd_data = rs1_data & rs2_data;
                        end
                endcase
        endcase
    end

    always_ff @(posedge clk_i) begin : memory 
        if(!rstn_i) begin
        end else if (mem_wr_enable) begin
            case(instr_d[14:12])
                F3_SB : dmem[mem_wr_addr[$clog2(MEM_SIZE)-1:0]][7:0 ] <= rs2_data[7:0 ];
                F3_SH : dmem[mem_wr_addr[$clog2(MEM_SIZE)-1:0]][15:0] <= rs2_data[15:0];
                F3_SW : dmem[mem_wr_addr[$clog2(MEM_SIZE)-1:0]]       <= rs2_data;
            endcase
        end
    end

    always_ff @(posedge clk_i) begin : register_file
        if(!rstn_i) begin
            for (int i=0; i<32; ++i) begin
                rf[i] <= '0;
            end
        end else if (rf_wr_enable && instr_d[11:7] != '0) begin
            rf[instr_d[11:7]] <= rd_data;                
        end
    end

endmodule
