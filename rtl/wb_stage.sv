module wb_stage
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input  logic      clk_i,
    input  logic      rst_i,
    input  mm_stage_t mm_i,
    output wb_stage_t wb_o
);

    always_comb begin
        wb_o.is_wb = mm_i.is_wb;
        wb_o.rd    = mm_i.rd;
        wb_o.data  = mm_i.data;
    end

endmodule
