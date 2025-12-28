module tb ();

    logic [riscv_pkg::XLEN-1:0] addr;
    logic [riscv_pkg::XLEN-1:0] data;
    logic [riscv_pkg::XLEN-1:0] pc;
    logic [riscv_pkg::XLEN-1:0] instr;
    logic [                4:0] reg_addr;
    logic [riscv_pkg::XLEN-1:0] reg_data;
    logic                       update;
    logic                       clk;
    logic                       rstn;

    core_model i_core_model(
        .clk_i(clk),
        .rstn_i(rstn),
        .addr_i(addr),
        .update_o(update),
        .data_o(data),
        .pc_o(pc),
        .instr_o(instr),
        .reg_addr_o(reg_addr),
        .reg_data_o(reg_data)
    );

    integer file_pointer;
    
    initial begin
        file_pointer = $fopen("model.log","w");
        #4;
        forever begin
            if (update) begin
                if (reg_addr == 0) begin
                    $fdisplay(file_pointer, "0x%8h (0x%8h)", pc, instr);
                end else begin
                    if (reg_addr > 9) begin
                        $fdisplay(file_pointer, "0x%8h (0x%8h) x%0d 0x%8h", pc, instr, reg_addr, reg_data);
                    end else begin
                        $fdisplay(file_pointer, "0x%8h (0x%8h) x%0d  0x%8h", pc, instr, reg_addr, reg_data);
                    end
                end
                #2;
            end
        end
    end

    initial forever begin
        clk = 0;
        #1;
        clk = 1;
        #1;
    end

    initial begin
        rstn = 0;
        #4;
        rstn = 1;
        #3877;
        /*
        for (int i=0; i<10; i++) begin
            addr = i;
            $display("data @ mem[0x%8h] = %8h", addr, data);
        end
        */
        $fclose(file_pointer);
        #10;

        check_diff_result();

        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars();
    end
    
    task check_diff_result();
        integer diff_file;
        integer char;
        logic is_empty;
        
        $system("diff ./model.log ./test/test.log > diff.log");
        diff_file = $fopen("diff.log", "r");
        
        if (diff_file == 0) begin
            $display("\n╔═══════════════════════════════════════════╗");
            $display("║                                           ║");
            $display("║     --------  TEST FAILED  --------       ║");
            $display("║                                           ║");
            $display("║      RTL differs from Golden Model        ║");
            $display("║        See diff.log for details           ║");
            $display("║                                           ║");
            $display("╚═══════════════════════════════════════════╝\n");
        end else begin

        char = $fgetc(diff_file);
        is_empty = (char == -1);            
        $fclose(diff_file);
            
        if (is_empty) begin
            $display("\n╔═══════════════════════════════════════════╗");
            $display("║                                           ║");
            $display("║     --------  TEST PASSED  --------       ║");
            $display("║                                           ║");
            $display("║     RTL matches Golden Model perfectly    ║");
            $display("║                                           ║");
            $display("╚═══════════════════════════════════════════╝\n");
        end else begin 
            $display("\n╔═══════════════════════════════════════════╗");
            $display("║                                           ║");
            $display("║     --------  TEST FAILED  --------       ║");
            $display("║                                           ║");
            $display("║      RTL differs from Golden Model        ║");
            $display("║        See diff.log for details           ║");
            $display("║                                           ║");
            $display("╚═══════════════════════════════════════════╝\n");
        end
        end
    endtask
endmodule