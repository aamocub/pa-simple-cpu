module id_stage
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input  if_stage_t fetch_i,
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
            OPCODE_LUI, OPCODE_AUIPC: begin
                decode_o.imm <= u_imm;
            end
            OPCODE_JAL: begin
                decode_o.imm <= j_imm;
            end
            OPCODE_IMM, OPCODE_LOAD, OPCODE_JALR: begin
                decode_o.imm <= i_imm;
            end
            OPCODE_STORE: begin
                decode_o.imm <= s_imm;
            end
            OPCODE_BRANCH: begin
                decode_o.imm <= b_imm;
            end
            default: decode_o.imm <= '0;
        endcase
    end

    // Instruction decoding
    always_comb begin
    end

endmodule
