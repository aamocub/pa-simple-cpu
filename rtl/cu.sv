module cu
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input logic clk_i,
    input logic rst_i,
    input if_stage_t if_i,
    input if_stage_t if_id_i,
    input id_stage_t id_i,
    input id_stage_t id_ex_i,
    input ex_stage_t ex_i,
    input ex_stage_t ex_mm_i,
    input mm_stage_t mm_i,
    input mm_stage_t mm_wb_i,
    input wb_stage_t wb_i,

    input  hf_entry_t                              hf_head_entry_i,
    input  logic                                   hf_full_i,
    output logic                                   hf_commit_o,
    input  logic      [$clog2(HISTFILE_DEPTH)-1:0] hf_head_i,
    input  logic      [$clog2(HISTFILE_DEPTH)-1:0] hf_tail_i,
    output logic      [$clog2(HISTFILE_DEPTH)-1:0] hf_entry_to_read_o,
    output logic                                   hf_recovery_o,
    output logic                                   hf_reset_o,

    output cu_if_t if_o,
    output cu_id_t id_o,
    output cu_ex_t ex_o,
    output cu_mm_t mm_o,
    output cu_wb_t wb_o
);
    wire ex_rs1_hazard = ex_mm_i.is_wb && ex_mm_i.rd != 0 && ex_mm_i.rd == id_ex_i.rs1;
    wire ex_rs2_hazard = ex_mm_i.is_wb && ex_mm_i.rd != 0 && ex_mm_i.rd == id_ex_i.rs2;
    wire mm_rs1_hazard = mm_wb_i.is_wb && mm_wb_i.rd != 0 && mm_wb_i.rd == id_ex_i.rs1 && !ex_rs1_hazard;
    wire mm_rs2_hazard = mm_wb_i.is_wb && mm_wb_i.rd != 0 && mm_wb_i.rd == id_ex_i.rs2 && !ex_rs2_hazard;

    wire ex_rd_hazard = ex_mm_i.valid && ex_mm_i.is_wb && ex_mm_i.rd != 0 && ex_mm_i.rd == id_i.rd;
    wire mm_rd_hazard = mm_wb_i.valid && mm_wb_i.is_wb && mm_wb_i.rd != 0 && mm_wb_i.rd == id_i.rd;
    wire waw_hazard = 0 && (ex_rd_hazard || mm_rd_hazard);

    wire is_exception = |hf_head_entry_i.evec && hf_head_entry_i.ready;
    wire is_taken = ex_i.is_taken;

    // verilog_format: off
    enum { IDLE, HF_EXCEP_RECOVERY } state, next_state;
    // verilog_format: on
    logic from_recovery;
    assign hf_recovery_o = state == HF_EXCEP_RECOVERY ? 1 : 0;
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) state <= IDLE;
        else state <= next_state;
    end
    always_comb begin
        hf_reset_o = 0;
        unique case (state)
            IDLE: next_state = is_exception ? HF_EXCEP_RECOVERY : state;
            HF_EXCEP_RECOVERY: begin
                next_state = HF_EXCEP_RECOVERY;
                if (hf_entry_to_read_o == hf_head_i) begin
                    hf_reset_o = 1;
                    next_state = IDLE;
                end
            end
        endcase
    end
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            hf_entry_to_read_o <= 0;
            from_recovery <= 0;
        end else begin
            unique case (state)
                IDLE: begin
                    hf_entry_to_read_o <= hf_tail_i;
                    from_recovery <= 0;
                end
                HF_EXCEP_RECOVERY: begin
                    if (hf_entry_to_read_o != hf_head_i) begin
                        from_recovery <= 1;
                        hf_entry_to_read_o <= (hf_entry_to_read_o - 1) % HISTFILE_DEPTH;
                    end else begin
                    end
                end
            endcase
        end
    end

    always_comb begin : histfile_ctrl
        hf_commit_o = hf_head_entry_i.valid && hf_head_entry_i.ready && |hf_head_entry_i.evec == 0;
    end

    always_comb begin : IF_stage
        if_o.stall = waw_hazard | hf_recovery_o | hf_full_i | ex_i.do_stall | mm_i.do_stall;
        if_o.flush = is_exception | is_taken;

        // PC selection logic
        if_o.pcsel = is_exception | from_recovery ? 2 : is_taken ? 1 : 0;
        if_o.addr  = is_taken ? ex_i.alu_result : 0;
    end

    always_comb begin : ID_stage
        id_o.stall = hf_recovery_o | hf_full_i | ex_i.do_stall | mm_i.do_stall;
        id_o.flush = is_taken | is_exception;
        id_o.epc   = hf_head_entry_i.pc;
        id_o.ewe   = is_exception;
    end

    always_comb begin : EX_stage
        ex_o.stall = hf_full_i | ex_i.do_stall | mm_i.do_stall;
        ex_o.flush = is_taken | is_exception;

        // ALU input mux select
        // verilog_format: off
        ex_o.alu_mux_a_sel = id_ex_i.is_br ? 1 : // pc
                             ex_rs1_hazard ? 2 : // rd from EX/MM
                             mm_rs1_hazard ? 3 : // rd from MM/WB
                                             0;  // rs1 from decode

        ex_o.alu_mux_b_sel = id_ex_i.uses_rs2 && ex_rs2_hazard ? 1 : // rd from EX/MM
                             id_ex_i.uses_rs2 && mm_rs2_hazard ? 2 : // rd from MM/WB
                                              id_ex_i.uses_rs2 ? 3 : // rs2 from decode
                                                                 0;  // immediate

        ex_o.cmp_mux_a_sel = ex_rs1_hazard ? 1 : // rd from EX/MM
                             mm_rs1_hazard ? 2 : // rd from MM/WB
                                             0;  // rs1 from decode

        ex_o.cmp_mux_b_sel = ex_rs2_hazard ? 1 : // rd from EX/MM
                             mm_rs2_hazard ? 2 : // rd from MM/WB
                                             0;  // rs2 from decode

        // ex_o.alu_mux_a_sel = id_ex_i.is_br ? 1 : ex_rs1_hazard ? 2 : mm_rs1_hazard ? 3 : 0;
        // ex_o.alu_mux_b_sel = ex_rs2_hazard ? 2 : mm_rs2_hazard ? 3 : id_ex_i.uses_rs2 ? 1 : 0;
        // ex_o.cmp_mux_a_sel = ex_rs1_hazard ? 1 : mm_rs1_hazard ? 2 : 0;
        // ex_o.cmp_mux_b_sel = ex_rs2_hazard ? 1 : mm_rs2_hazard ? 2 : 0;
        // verilog_format: on
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
