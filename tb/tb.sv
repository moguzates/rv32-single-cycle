module tb ();
    import riscv_pkg::*;

    logic [riscv_pkg::XLEN-1:0] addr;
    logic [riscv_pkg::XLEN-1:0] data;
    logic                       irq;
    logic [riscv_pkg::XLEN-1:0] pc;
    logic [riscv_pkg::XLEN-1:0] instr;
    logic [                4:0] reg_addr;
    logic [riscv_pkg::XLEN-1:0] reg_data;
    logic                       update;
    logic                       clk;
    logic                       rstn;
    logic [6:0] last_data = 7'hFF;

    core_model i_core_model(
        .clk_i(clk),
        .rstn_i(rstn),
        .irq_i(irq),
        .addr_i(addr),
        .update_o(update),
        .data_o(data),
        .pc_o(pc),
        .instr_o(instr),
        .reg_addr_o(reg_addr),
        .reg_data_o(reg_data)
    );

    initial forever begin
        clk = 0;
        #1;
        clk = 1;
        #1;
    end

    initial begin
        irq = 0;
        rstn = 0;
        #100;      
        rstn = 1;

        /*
        // INTERRUPT (BUTTON) TEST
        $display("\n[TB] >>> BUTTON PRESSED: RESETTING PROGRAM... <<<\n");
        irq = 1;
        #40; 
        irq = 0;
        */

        #5000000;
        $display("\n[TB] Simulation Timeout.");
        $finish;
    end

    always @(posedge clk) begin
        // Debugging line to track instruction flow
        if (rstn) $display("[DEBUG] PC: 0x%h | Instr: 0x%h", pc, instr);

        // Catch EBREAK instruction (0x00100073) to terminate
        if (rstn && (instr == 32'h00100073)) begin
            $display("\n[TB] >>> EBREAK DETECTED. PROGRAM EXECUTED SUCCESSFULLY. <<<");
            $display("[TB] Final PC: 0x%h", pc);
            #10;
            $finish;
        end

        if (i_core_model.mem_wr_enable && (i_core_model.mem_wr_addr == 32'h400)) begin
            
            if (i_core_model.mem_wr_data[6:0] != last_data) begin
                last_data = i_core_model.mem_wr_data[6:0];
                
                //$write("\033[H\033[J"); 
                $display("====================================");
                $display("     RISC-V 7-SEGMENT MONITOR       ");
                $display("====================================");
                $display("  Sim Time : %0t ps", $time);
                $display("  PC Value : 0x%h", pc);
                $display("------------------------------------");
                
                case (last_data)
                    7'h3F: $display("        -- \n       |  | \n            \n       |  | \n        --    [ 0 ]");
                    7'h06: $display("           \n          | \n            \n          | \n              [ 1 ]");
                    7'h5B: $display("        -- \n          | \n        -- \n       |    \n        --    [ 2 ]");
                    7'h4F: $display("        -- \n          | \n        -- \n          | \n        --    [ 3 ]");
                    7'h66: $display("           \n       |  | \n        -- \n          | \n              [ 4 ]");
                    7'h6D: $display("        -- \n       |    \n        -- \n          | \n        --    [ 5 ]");
                    7'h7D: $display("        -- \n       |    \n        -- \n       |  | \n        --    [ 6 ]");
                    7'h07: $display("        -- \n          | \n            \n          | \n              [ 7 ]");
                    7'h7F: $display("        -- \n       |  | \n        -- \n       |  | \n        --    [ 8 ]");
                    7'h6F: $display("        -- \n       |  | \n        -- \n          | \n        --    [ 9 ]");
                    default: $display("     UNKNOWN VALUE: 0x%h", last_data);
                endcase
                $display("------------------------------------");
                $display("====================================");
            end
        end
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
    end

endmodule