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
    // Hay algo mal con los bypasses y logica de deteccion de dependencias entre instrucciones.
    logic ex_rs1_hazard = ex_mm_i.is_wb && ex_mm_i.rd != 0 && ex_mm_i.rd == id_ex_i.rs1;
    logic ex_rs2_hazard = ex_mm_i.is_wb && ex_mm_i.rd != 0 && ex_mm_i.rd == id_ex_i.rs2;
    logic mm_rs1_hazard = mm_wb_i.is_wb && mm_wb_i.rd != 0 && mm_wb_i.rd == id_ex_i.rs1 && !ex_rs1_hazard;
    logic mm_rs2_hazard = mm_wb_i.is_wb && mm_wb_i.rd != 0 && mm_wb_i.rd == id_ex_i.rs2 && !ex_rs2_hazard;

    logic is_exception = |wb_i.evec;
    logic is_taken = ex_mm_i.is_taken;

    always_comb begin : IF_stage
        if_o.stall = ex_i.do_stall | mm_i.do_stall;
        if_o.flush = is_exception;

        // PC selection logic
        if_o.pcsel = is_exception ? 2 : is_taken ? 1 : 0;
        if_o.addr  = is_taken ? ex_mm_i.alu_result : 0;
    end

    always_comb begin : ID_stage
        id_o.stall = ex_i.do_stall | mm_i.do_stall;
        id_o.flush = is_taken | is_exception;
        id_o.epc   = wb_i.pc;
        id_o.ewe   = is_exception;
    end

    always_comb begin : EX_stage
        ex_o.stall = ex_i.do_stall | mm_i.do_stall;
        ex_o.flush = is_taken | is_exception;

        // ALU input mux select
        ex_o.alu_mux_a_sel = id_ex_i.is_br ? 1 : ex_rs1_hazard ? 2 : mm_rs1_hazard ? 3 : 0;
        ex_o.alu_mux_b_sel = id_ex_i.uses_rs2 ? 0 : ex_rs2_hazard ? 2 : mm_rs2_hazard ? 3 : 0;
        ex_o.cmp_mux_a_sel = ex_rs1_hazard ? 1 : mm_rs1_hazard ? 2 : 0;
        ex_o.cmp_mux_b_sel = ex_rs2_hazard ? 1 : mm_rs2_hazard ? 2 : 0;
    end

    always_comb begin : MM_stage
        mm_o.stall = mm_i.do_stall;
        mm_o.flush = is_exception;
    end

    always_comb begin : WB_stage
        wb_o.stall = 0;
        wb_o.flush = is_exception;
    end
endmodule
