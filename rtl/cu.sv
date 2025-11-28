module cu
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input if_stage_t if_i,
    input if_stage_t if_id_i,
    input id_stage_t id_i,
    input id_stage_t id_ex_i,
    input ex_stage_t ex_i,
    input ex_stage_t ex_mm_i,
    input mm_stage_t mm_i,
    input mm_stage_t mm_wb_i,
    input wb_stage_t wb_i,

    output cu_if_t if_o,
    output cu_id_t id_o,
    output cu_ex_t ex_o,
    output cu_mm_t mm_o,
    output cu_wb_t wb_o
);
    logic ex_rs1_hazard;
    logic ex_rs2_hazard;
    logic mm_rs1_hazard;
    logic mm_rs2_hazard;

    always_comb begin
        ex_rs1_hazard = ex_mm_i.is_wb && ex_mm_i.rd != 0 && ex_mm_i.rd == id_ex_i.rs1;
        ex_rs2_hazard = ex_mm_i.is_wb && ex_mm_i.rd != 0 && ex_mm_i.rd == id_ex_i.rs2;
        mm_rs1_hazard = mm_wb_i.is_wb && mm_wb_i.rd != 0 && mm_wb_i.rd == id_ex_i.rs1 && !ex_rs1_hazard;
        mm_rs2_hazard = mm_wb_i.is_wb && mm_wb_i.rd != 0 && mm_wb_i.rd == id_ex_i.rs2 && !ex_rs2_hazard;

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

        if_o.taken = ex_mm_i.is_taken;
        if (ex_mm_i.is_taken) begin  // Branch
            id_o.flush = 1;
            ex_o.flush = 1;
            if_o.addr  = ex_mm_i.alu_result;
        end else if (ex_i.do_stall) begin  // ALU stall
            if_o.stall = 1;
            id_o.stall = 1;
            ex_o.stall = 1;
        end

        ex_o.alu_mux_a_sel = id_ex_i.is_br ? 1 : ex_rs1_hazard ? 2 : mm_rs1_hazard ? 3 : 0;
        ex_o.alu_mux_b_sel = id_ex_i.uses_rs2 ? 1 : ex_rs2_hazard ? 2 : mm_rs2_hazard ? 3 : 0;
        ex_o.cmp_mux_a_sel = ex_rs1_hazard ? 1 : mm_rs1_hazard ? 2 : 0;
        ex_o.cmp_mux_b_sel = ex_rs2_hazard ? 1 : mm_rs2_hazard ? 2 : 0;

        if (mm_i.do_stall) begin
            if_o.stall = 1;
            id_o.stall = 1;
            ex_o.stall = 1;  // TODO: It should be possible for EX to continue multiplying when stalled
            // TODO: mm_o.stall = 1; ?
        end
    end

endmodule
