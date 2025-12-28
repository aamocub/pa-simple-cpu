/*
    The overview of the CPU core.
    Each stage is divided into its own module. Each module has a series of inputs and outputs.
    For the pipeline registers, it will be its own registers, outside of the module.
*/

module core
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter DEBUG = 0
) (
    input logic clk_i,
    input logic rst_i,

    output mem_read_req_t   read_req,
    input  mem_read_resp_t  read_resp,
    output mem_write_req_t  write_req,
    input  mem_write_resp_t write_resp
);


    if_stage_t if_out, if_id;
    id_stage_t id_out, id_ex;
    ex_stage_t ex_out, ex_mm;
    mm_stage_t mm_out, mm_wb;
    wb_stage_t wb_out, wb_id;

    if_req_t if_req;
    if_resp_t if_resp;
    mm_read_req_t mm_read_req;
    mm_read_resp_t mm_read_resp;
    mm_write_req_t mm_write_req;
    mm_write_resp_t mm_write_resp;

    cu_if_t cu_if;
    cu_id_t cu_id;
    cu_ex_t cu_ex;
    cu_mm_t cu_mm;
    cu_wb_t cu_wb;

    cu cu (
        .if_i(if_out),
        .if_id_i(if_id),
        .id_i(id_out),
        .id_ex_i(id_ex),
        .ex_i(ex_out),
        .ex_mm_i(ex_mm),
        .mm_i(mm_out),
        .mm_wb_i(mm_wb),
        .wb_i(wb_out),
        .if_o(cu_if),
        .id_o(cu_id),
        .ex_o(cu_ex),
        .mm_o(cu_mm),
        .wb_o(cu_wb)
    );

    mem_arbitrer #() mem_arbitrer (
        .clk_i           (clk_i),
        .rst_i           (rst_i),
        .if_req_i        (if_req),
        .if_resp_o       (if_resp),
        .mm_read_req_i   (mm_read_req),
        .mm_read_resp_o  (mm_read_resp),
        .mm_write_req_i  (mm_write_req),
        .mm_write_resp_o (mm_write_resp),
        .mem_write_req_o (write_req),
        .mem_write_resp_i(write_resp),
        .mem_read_req_o  (read_req),
        .mem_read_resp_i (read_resp)
    );

    // ----------------------------------------------------------------------------------------------------------------
    // IF Stage
    // ----------------------------------------------------------------------------------------------------------------


    if_stage if_stage (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .cu_i  (cu_if),
        .req_o (if_req),
        .resp_i(if_resp),
        .if_o  (if_out)
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
        .default_i('{default: '0, op: ADDI, mem_width: WORD}),
        .d_i      (id_out),
        .q_o      (id_ex)
    );

    // ----------------------------------------------------------------------------------------------------------------
    // EX Stage
    // ----------------------------------------------------------------------------------------------------------------

    ex_stage ex_stage (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .id_i(id_ex),
        .cu_i(cu_ex),
        .bypass_mm_data(ex_mm.alu_result),
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

    // ----------------------------------------------------------------------------------------------------------------
    // M Stage
    // ----------------------------------------------------------------------------------------------------------------

    mm_stage mm_stage (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .ex_i(ex_mm),
        .read_req_o(mm_read_req),
        .read_resp_i(mm_read_resp),
        .write_req_o(mm_write_req),
        .write_resp_i(mm_write_resp),
        .mm_o(mm_out)
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
        .mm_i (mm_wb),
        .wb_o (wb_out)
    );

endmodule
