module top
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input clk_i,
    input rst_i
);
    memory_intf mem_io ();

    core #(
        .DEBUG(0)
    ) core (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .mem_io(mem_io.ARB)
    );

    memory memory (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .mem_io(mem_io.MEM)
    );
endmodule
