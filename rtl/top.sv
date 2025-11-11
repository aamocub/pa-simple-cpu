/*
    The overview of the CPU core.
    Each stage is divided into its own module. Each module has a series of inputs and outputs.
    For the pipeline registers, it will be its own registers, outside of the module.
*/

module top
    import pa_pkg::*;
    import riscv_pkg::*;
#(
    parameter DEBUG = 0
) (
    input logic clk_i,
    input logic rst_i
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

    cu cu (
        .if_i(if_out),
        .id_i(id_out),
        .ex_i(ex_out),
        .mm_i(mm_out),
        .wb_i(wb_out),
        .if_o(cu_if),
        .id_o(cu_id),
        .ex_o(cu_ex),
        .mm_o(cu_mm),
        .wb_o(cu_wb)
    );

    // ----------------------------------------------------------------------------------------------------------------
    // IF Stage
    // ----------------------------------------------------------------------------------------------------------------


    if_stage if_stage (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .ctrl_i(cu_if),
        .req_o (),
        .resp_i(),
        .if_o  (if_out)
    );

    register #(
        .reg_t(if_stage_t)
    ) if_id_pipeline_reg (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .en_i     (!cu_id.stall),
        .flush_i  (cu_id.flush),
        .default_i('{instr: NOP_INSTR}),
        .d_i      (if_out),
        .q_o      (if_id)
    );

    // ----------------------------------------------------------------------------------------------------------------
    // ID Stage
    // ----------------------------------------------------------------------------------------------------------------

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
        .default_i('{default: '0, op: ADDI}),
        .d_i      (id_out),
        .q_o      (id_ex)
    );

    // ----------------------------------------------------------------------------------------------------------------
    // EX Stage
    // ----------------------------------------------------------------------------------------------------------------

    ex_stage ex_stage (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .id_i (id_reg),
        .ex_o (ex_out)
    );

    register #(
        .reg_t(ex_stage_t)
    ) ex_mm_pipeline_reg (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .en_i     (!cu_mm.stall),
        .flush_i  (cu_mm.flush),
        .default_i('{default: '0}),
        .d_i      (ex_out),
        .q_o      (ex_mm)
    );

    // ----------------------------------------------------------------------------------------------------------------
    // M Stage
    // ----------------------------------------------------------------------------------------------------------------

    mm_stage mm_stage (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .ex_i (ex_reg),
        .mm_o (mm_out)
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

    // ----------------------------------------------------------------------------------------------------------------
    // WB Stage
    // ----------------------------------------------------------------------------------------------------------------

    wb_stage wb_stage (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .mm_i (mm_reg),
        .wb_o (wb_out)
    );

endmodule
