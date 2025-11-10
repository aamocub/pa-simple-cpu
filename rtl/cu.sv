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
        // Do not stall by default
        if_o.stall = 0;
        id_o.stall = 0;
        ex_o.stall = 0;
        mm_o.stall = 0;
        wb_o.stall = 0;

        // Do not flush by default
        if_o.flush = 0;
        id_o.flush = 0;
        ex_o.flush = 0;
        mm_o.flush = 0;
        wb_o.flush = 0;

        if_o.taken = ex_i.is_taken;
        if (ex_i.is_taken) begin  // Branch
            id_o.flush = 1;
            ex_o.flush = 1;
            if_o.addr  = ex_i.alu_result;
        end
    end

endmodule
