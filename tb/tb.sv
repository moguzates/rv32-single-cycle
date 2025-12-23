module tb ();

    logic [riscv_pkg::XLEN-1:0] addr;
    logic [riscv_pkg::XLEN-1:0] data;
    logic [riscv_pkg::XLEN-1:0] pc;
    logic                       update;

    core_model i_core_model(
        .addr_i(addr),
        .update_o(update),
        .data_o(data),
        .pc_o(pc)
    );

    initial begin
        forever begin
            if (update) begin
                $display("pc: %0h", pc);
                #1;
            end
        end
    end

    initial begin
        #10;
        $finish;
    end

   initial begin
      $dumpfile("dump.vcd");
      $dumpvars();
   end

endmodule