/* ------------------------------------------------------------------------------------------------------------------ */
/*                                                        Core                                                        */
/* ------------------------------------------------------------------------------------------------------------------ */

module core
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter DEBUG = 0
) (
    input logic clk_i,
    input logic rst_i,
    memory_intf.CL mem_a_io,
    memory_intf.CL mem_b_io
);


    if_stage_t if_out, if_id;
    id_stage_t id_out, id_ex;
    ex_stage_t ex_out, ex_mm;
    mm_stage_t mm_out, mm_wb;
    wb_stage_t wb_out, wb_id;

    cu_if_t cu_if;
    cu_id_t cu_id;
    cu_ex_t cu_ex;
    cu_mm_t cu_mm;
    cu_wb_t cu_wb;

    memory_intf icache_port ();
    memory_intf dcache_port ();
    memory_intf #(.DATA_WIDTH(CACHE_LINE_LEN)) icache_arb_port ();
    memory_intf #(.DATA_WIDTH(CACHE_LINE_LEN)) dcache_arb_port ();

    cache icache (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .core_io(icache_port.SV),
        .mem_io (mem_a_io)
    );

    cache dcache (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .core_io(dcache_port.SV),
        .mem_io (mem_b_io)
    );

    cu cu (
        .if_i   (if_out),
        .if_id_i(if_id),
        .id_i   (id_out),
        .id_ex_i(id_ex),
        .ex_i   (ex_out),
        .ex_mm_i(ex_mm),
        .mm_i   (mm_out),
        .mm_wb_i(mm_wb),
        .wb_i   (wb_out),
        .if_o   (cu_if),
        .id_o   (cu_id),
        .ex_o   (cu_ex),
        .mm_o   (cu_mm),
        .wb_o   (cu_wb)
    );

    // mem_arbitrer mem_arbitrer (
    //     .clk_i    (clk_i),
    //     .rst_i    (rst_i),
    //     .icache_io(icache_arb_port.SV),
    //     .dcache_io(dcache_arb_port.SV),
    //     .mem_io   (mem_io)
    // );

    /* -------------------------------------------------------------------------------------------------------------- */
    /*                                             Instruction Fetch Stage                                            */
    /* -------------------------------------------------------------------------------------------------------------- */

    if_stage if_stage (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .cu_i  (cu_if),
        .if_o  (if_out),
        .mem_io(icache_port.CL)
    );

    register #(
        .reg_t(if_stage_t)
    ) if_id_pipeline_reg (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .en_i     (!cu_id.stall),
        .flush_i  (cu_id.flush),
        .default_i('{default: '0, instr: NOP_INSTR}),
        .d_i      (if_out),
        .q_o      (if_id)
    );

    /* -------------------------------------------------------------------------------------------------------------- */
    /*                                            Instruction Decode Stage                                            */
    /* -------------------------------------------------------------------------------------------------------------- */

    id_stage id_stage (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .fetch_i  (if_id),
        .from_wb_i(wb_out),
        .decode_o (id_out)
    );

    register #(
        .reg_t(id_stage_t)
    ) id_ex_pipeline_reg (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .en_i     (!cu_ex.stall),
        .flush_i  (cu_ex.flush),
        .default_i('{default: '0, op: ADDI, mem_width: WORD}),
        .d_i      (id_out),
        .q_o      (id_ex)
    );

    register #(
        .reg_t(logic [XLEN-1:0])
    ) exception_pc_reg (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .en_i     (cu_id.ewe),
        .flush_i  (0),
        .default_i(0),
        .d_i      (cu_id.epc),
        .q_o      ()
    );

    /* -------------------------------------------------------------------------------------------------------------- */
    /*                                                 Execution Stage                                                */
    /* -------------------------------------------------------------------------------------------------------------- */

    ex_stage ex_stage (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .id_i(id_ex),
        .cu_i(cu_ex),
        .bypass_mm_data(mm_out.data),
        .bypass_wb_data(mm_wb.data),
        .ex_o(ex_out)
    );

    register #(
        .reg_t(ex_stage_t)
    ) ex_mm_pipeline_reg (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .en_i     (!cu_mm.stall),
        .flush_i  (cu_mm.flush),
        .default_i('{default: '0, mem_width: WORD}),
        .d_i      (ex_out),
        .q_o      (ex_mm)
    );

    /* -------------------------------------------------------------------------------------------------------------- */
    /*                                                  Memory Stage                                                  */
    /* -------------------------------------------------------------------------------------------------------------- */

    mm_stage mm_stage (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .ex_i  (ex_mm),
        .mm_o  (mm_out),
        .mem_io(dcache_port.CL)
    );

    register #(
        .reg_t(mm_stage_t)
    ) mm_wb_pipeline_reg (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .en_i     (!cu_wb.stall),
        .flush_i  (cu_wb.flush),
        .default_i('{default: '0}),
        .d_i      (mm_out),
        .q_o      (mm_wb)
    );

    /* -------------------------------------------------------------------------------------------------------------- */
    /*                                                 Writeback Stage                                                */
    /* -------------------------------------------------------------------------------------------------------------- */

    wb_stage wb_stage (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .mm_i (mm_wb),
        .wb_o (wb_out)
    );

endmodule
