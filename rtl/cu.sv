module cu
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input if_stage_t if_i,
    input id_stage_t id_i,
    input ex_stage_t ex_i,
    output cu_if_t if_o
);
    always_comb begin
        if_o.pc_sel = ex_i.is_taken;
    end

endmodule
