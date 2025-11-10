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
        end else if (ex_i.do_stall) begin  // ALU stall
            if_o.stall = 1;
            id_o.stall = 1;
        end

        if (mm_i.do_stall) begin
            if_o.stall = 1;
            id_o.stall = 1;
            ex_o.stall = 1;  // TODO: It should be possible for EX to continue multiplying when stalled
        end
    end

endmodule
