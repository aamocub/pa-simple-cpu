module top
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input clk_i,
    input rst_i
);
    memory_intf #(.DATA_WIDTH(128)) mem_a_io ();
    memory_intf #(.DATA_WIDTH(128)) mem_b_io ();

    core #(
        .DEBUG(0)
    ) core (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .mem_a_io(mem_a_io.CL),
        .mem_b_io(mem_b_io.CL)
    );

    memory memory (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .mem_a_io(mem_a_io.SV),
        .mem_b_io(mem_b_io.SV)
    );
endmodule
