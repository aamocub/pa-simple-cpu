module cu
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input if_stage_t if_i,
    input id_stage_t id_i,
    input ex_stage_t ex_i,
    input mm_stage_t mm_i,
    input wb_stage_t wb_i,

    output cu_if_t if_o,
    output cu_id_t id_o,
    output cu_ex_t ex_o,
    output cu_mm_t mm_o,
    output cu_wb_t wb_o
);
    always_comb begin
        if_o.pc_sel = ex_i.is_taken;
    end

endmodule
