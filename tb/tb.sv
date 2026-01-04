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

        #50000000;
        $display("\n[TB] Simulation Timeout.");
        $finish;
    end

    always @(posedge clk) begin
        if (i_core_model.mem_wr_enable && (i_core_model.mem_wr_addr == 32'h400)) begin
            if (i_core_model.mem_wr_data[6:0] != last_data) begin
                last_data = i_core_model.mem_wr_data[6:0];
                
                $display("\n--- The Number 0x%h ---", last_data);
                case (last_data)
                    7'h3F: $display("  -- \n |  | \n |  | \n  --  [ 0 ]");
                    7'h06: $display("     \n    | \n    | \n      [ 1 ]");
                    7'h5B: $display("  -- \n    | \n  -- \n |    \n  --  [ 2 ]");
                    7'h4F: $display("  -- \n    | \n  -- \n    | \n  --  [ 3 ]");
                    7'h66: $display("     \n |  | \n  -- \n    | \n      [ 4 ]");
                    7'h6D: $display("  -- \n |    \n  -- \n    | \n  --  [ 5 ]");
                    7'h7D: $display("  -- \n |    \n  -- \n |  | \n  --  [ 6 ]");
                    7'h07: $display("  -- \n    | \n     \n    | \n      [ 7 ]");
                    7'h7F: $display("  -- \n |  | \n  -- \n |  | \n  --  [ 8 ]");
                    7'h6F: $display("  -- \n |  | \n  -- \n    | \n  --  [ 9 ]");
                    default: $display(" VERI: 0x%h", last_data);
                endcase
            end
        end

        if (rstn && (instr == 32'h00100073)) begin
            $display("\n[TB] >>> PROGRAM BITTI (EBREAK) <<<");
            $finish;
        end
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
    end

endmodule