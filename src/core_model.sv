module core_model
    import riscv_pkg::*;
(
    input  logic [XLEN-1:0] addr_i,
    output logic            update_o,
    output logic [XLEN-1:0] data_o,
    output logic [XLEN-1:0] pc_o
);

    initial $display(":) :) :)");
    initial begin
        update_o = 0;
        #1;
        update_o = 1;
    end
endmodule
