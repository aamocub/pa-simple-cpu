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

    if_stage_t if_out, if_reg;
    id_stage_t id_out, id_reg;
    ex_stage_t ex_out, ex_reg;
    mm_stage_t mm_out, mm_reg;
    wb_stage_t wb_out, wb_reg;

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

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i || cu_if.flush) begin
            if_reg.instr <= NOP_INSTR;
        end else if (!cu_if.stall) begin
            if_reg <= if_out;
        end
    end

    // ----------------------------------------------------------------------------------------------------------------
    // ID Stage
    // ----------------------------------------------------------------------------------------------------------------

    if_stage_t if_id;

    register #(
        .reg_t(if_stage_t)
    ) if_id_pipeline_reg (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .en_i   (1),
        .flush_i(0),
        .d_i    (if_out),
        .q_o    (if_id)
    );

    id_stage id_stage (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .fetch_i  (if_reg),  // TODO: Convert if_reg to if_id
        .from_wb_i(wb_out),
        .decode_o (id_out)
    );

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i || cu_id.flush) begin
            id_reg.rs1      <= '0;
            id_reg.rs2      <= '0;
            id_reg.data_rs1 <= '0;
            id_reg.data_rs2 <= '0;
            id_reg.rd       <= '0;
            id_reg.is_wb    <= 0;
            id_reg.is_ld    <= 0;
            id_reg.is_st    <= 0;
            id_reg.uses_rs2 <= 0;
            id_reg.imm      <= '0;
            id_reg.op       <= ADDI;
        end else if (!cu_id.stall) begin
            id_reg <= id_out;
        end
    end

    // ----------------------------------------------------------------------------------------------------------------
    // EX Stage
    // ----------------------------------------------------------------------------------------------------------------

    ex_stage ex_stage (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .id_i (id_reg),
        .ex_o (ex_out)
    );

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i || cu_ex.flush) begin
            ex_reg.alu_result <= '0;
            ex_reg.is_taken   <= 0;
            ex_reg.is_wb      <= 0;
            ex_reg.is_ld      <= 0;
            ex_reg.is_st      <= 0;
            ex_reg.uses_rs2   <= 0;
            ex_reg.data_rs2   <= '0;
            ex_reg.rd         <= '0;
            ex_reg.do_stall   <= 0;
        end else if (!cu_ex.stall) begin
            ex_reg <= ex_out;
        end
    end

    // ----------------------------------------------------------------------------------------------------------------
    // M Stage
    // ----------------------------------------------------------------------------------------------------------------

    mm_stage mm_stage (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .ex_i (ex_reg),
        .mm_o (mm_out)
    );

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i || cu_mm.flush) begin
            mm_reg.data       <= '0;
            mm_reg.data_rs2   <= '0;
            mm_reg.is_wb      <= 0;
            mm_reg.do_stall   <= 0;
            mm_reg.rd         <= '0;
            mm_reg.read_req   <= '0;
            mm_reg.read_resp  <= '0;
            mm_reg.write_req  <= '0;
            mm_reg.write_resp <= '0;
        end else if (!cu_mm.stall) begin
            mm_reg <= mm_out;
        end
    end

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
