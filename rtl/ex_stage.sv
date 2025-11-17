module ex_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input logic clk_i,
    input logic rst_i,
    input id_stage_t id_i,
    output ex_stage_t ex_o
);
    always_comb begin
        ex_o.is_wb    = id_i.is_wb;
        ex_o.is_ld    = id_i.is_ld;
        ex_o.is_st    = id_i.is_st;
        ex_o.uses_rs2 = id_i.uses_rs2;
        ex_o.data_rs2 = id_i.data_rs2;
        ex_o.rd       = id_i.rd;
    end

    cmp cmp (
        .a_i  (id_i.data_rs1),
        .b_i  (id_i.data_rs2),
        .op_i (id_i.op),
        .out_o(ex_o.is_taken)
    );

    alu alu (
        .a_i     (id_i.is_br ? id_i.pc : id_i.data_rs1),
        .b_i     (id_i.uses_rs2 ? id_i.data_rs2 : id_i.imm),
        .opcode_i(id_i.op),
        .out_o   (ex_o.alu_result),
        .stall_o (ex_o.do_stall)
    );

endmodule
