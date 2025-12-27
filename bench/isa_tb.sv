
module isa_tb
    import riscv_pkg::*;
    import pa_pkg::*;
();
    memory_intf mem_io ();

    logic clk_i;
    logic rst_i;
    localparam CLK_PERIOD = 20;
    always #(CLK_PERIOD / 2) clk_i <= ~clk_i;

    core #(
        .DEBUG(0)
    ) core (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .mem_io(mem_io.CL)
    );

    memory #(
        .DEBUG(1)
    ) memory (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .mem_io(mem_io.SV)
    );

    initial begin
        $dumpfile("isa_tb.fst");
        $dumpvars(0, isa_tb);
        clk_i = 1;
        rst_i = 1;
        #(CLK_PERIOD) rst_i = 0;
        #(CLK_PERIOD * 20);
        $finish();
    end

endmodule
