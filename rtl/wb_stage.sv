module wb_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input  logic      clk_i,
    input  logic      rst_i,
    input  mm_stage_t mm_i,
    output wb_stage_t wb_o
);

    always_comb begin : exceptions
        wb_o.evec = mm_i.evec;
    end

    always_comb begin : passthrough_signals
        wb_o.is_wb = mm_i.is_wb;
        wb_o.rd    = mm_i.rd;
        wb_o.pc    = mm_i.pc;
        wb_o.hf_id = mm_i.hf_id;
        wb_o.data  = mm_i.data;
    end

endmodule
