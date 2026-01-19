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

    logic hf_empty;
    logic hf_full;
    logic [$clog2(HISTFILE_DEPTH)-1:0] hf_tail;
    logic hf_issue;
    hf_entry_t hf_entry_in;
    logic hf_wren;
    logic [$clog2(HISTFILE_DEPTH)-1:0] hf_wrid;
    logic hf_ready;
    exception_t hf_evec;
    logic hf_rden;
    logic [$clog2(HISTFILE_DEPTH)-1:0] hf_rdid;
    logic [XLEN-1:0] hf_value;
    logic [XLEN-1:0] hf_rd;
    logic [$clog2(HISTFILE_DEPTH)-1:0] hf_head;
    logic hf_commit;
    hf_entry_t hf_entry_out;

    memory_intf icache_port ();
    memory_intf dcache_port ();
    memory_intf #(.DATA_WIDTH(CACHE_LINE_LEN)) icache_arb_port ();
    memory_intf #(.DATA_WIDTH(CACHE_LINE_LEN)) dcache_arb_port ();

    // Performance counters
    integer unsigned cycles;
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            cycles <= 0;
        end else begin
            cycles <= cycles + 1;
        end
    end

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
        .if_i           (if_out),
        .if_id_i        (if_id),
        .id_i           (id_out),
        .id_ex_i        (id_ex),
        .ex_i           (ex_out),
        .ex_mm_i        (ex_mm),
        .mm_i           (mm_out),
        .mm_wb_i        (mm_wb),
        .wb_i           (wb_out),
        .hf_head_entry_i(hf_entry_out),
        .hf_full_i      (hf_full),
        .hf_commit_o    (hf_commit),
        .if_o           (cu_if),
        .id_o           (cu_id),
        .ex_o           (cu_ex),
        .mm_o           (cu_mm),
        .wb_o           (cu_wb)
    );

    assign hf_issue = !cu_id.stall && id_out.valid && !cu_id.flush;
    assign hf_entry_in.ready = '0;
    assign hf_entry_in.valid = id_out.valid;
    assign hf_entry_in.evec = '0;
    assign hf_entry_in.pc = '0;
    assign hf_entry_in.miss = '0;
    assign hf_entry_in.rd = id_out.rd;
    assign hf_entry_in.value = id_out.data_rd;
    histfile #() histfile (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .empty_o (hf_empty),
        .full_o  (hf_full),
        .tail_i  (hf_tail),
        .issue_i (hf_issue),
        .entry_i (hf_entry_in),
        .wren_i  (wb_out.valid),
        .wrid_i  (wb_out.hf_id),
        .ready_i (wb_out.valid),
        .evec_i  (wb_out.evec),
        .rden_i  (),
        .rdid_i  (),
        .value_o (hf_value),
        .rd_o    (hf_rd),
        .head_i  (hf_head),
        .commit_i(hf_commit),
        .entry_o (hf_entry_out)
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

    register #(
        .reg_t(logic [$clog2(HISTFILE_DEPTH)-1:0])
    ) histfile_tail (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .en_i     (hf_issue),
        .flush_i  (0),
        .default_i(0),
        .d_i      ((hf_tail + 1) % HISTFILE_DEPTH),
        .q_o      (hf_tail)
    );

    id_stage id_stage (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .fetch_i  (if_id),
        .hf_id_i  (hf_tail),
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

    register #(
        .reg_t(logic [$clog2(HISTFILE_DEPTH)-1:0])
    ) histfile_head (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .en_i     (hf_commit),
        .flush_i  (0),
        .default_i(0),
        .d_i      ((hf_head + 1) % HISTFILE_DEPTH),
        .q_o      (hf_head)
    );

endmodule
