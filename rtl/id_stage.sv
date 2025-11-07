module id_stage
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input clk_i,
    input rst_i,
    input if_stage_t fetch_i,
    output id_stage_t decode_o
);

    logic [31:0] i_imm = {{20{fetch_i.instr[31]}}, fetch_i.instr.itype.imm};
    logic [31:0] s_imm = {{20{fetch_i.instr[31]}}, fetch_i.instr.stype.imm_1, fetch_i.instr.stype.imm_2};
    logic [31:0] b_imm = {
        {19{fetch_i.instr.btype.imm_1}}, fetch_i.instr.btype.imm_2, fetch_i.instr.btype.imm_3, fetch_i.instr.btype.imm_4
    };
    logic [31:0] u_imm = {fetch_i.instr.utype.imm, 12'b0};
    logic [31:0] j_imm = {
        {12{fetch_i.instr.jtype.imm_1}}, fetch_i.instr.jtype.imm_2, fetch_i.instr.jtype.imm_3, fetch_i.instr.jtype.imm_4
    };

    // Immediate
    always_comb begin
        case (fetch_i.instr.rtype.opcode)
            OPCODE_LUI, OPCODE_AUIPC: decode_o.imm <= u_imm;
            OPCODE_JAL: decode_o.imm <= j_imm;
            OPCODE_IMM, OPCODE_LOAD, OPCODE_JALR: decode_o.imm <= i_imm;
            OPCODE_STORE: decode_o.imm <= s_imm;
            OPCODE_BRANCH: decode_o.imm <= b_imm;
            default: decode_o.imm <= '0;
        endcase
    end

    // Instruction decoding
    always_comb begin
    end

    // Regfile access (in parallel to decoding)
    regfile #(
        .NUMREGS  (RF_NUMREGS),
        .DATAWIDTH(XLEN)
    ) regfile (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .re_a_i   (),
        .rdata_a_o(),
        .raddr_a_i(),
        .re_b_i   (),
        .rdata_b_o(),
        .raddr_b_i(),
        .we_i     (),
        .wdata_i  (),
        .waddr_i  ()
    );

endmodule
