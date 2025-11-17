module id_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input  logic      clk_i,
    input  logic      rst_i,
    input  if_stage_t fetch_i,
    input  wb_stage_t from_wb_i,
    output id_stage_t decode_o
);

    // TODO: change sign extension based on if the instruction uses sign or unsigned numbers
    logic [31:0] i_imm = {{20{fetch_i.instr[31]}}, fetch_i.instr.itype.imm};
    logic [31:0] s_imm = {{20{fetch_i.instr[31]}}, fetch_i.instr.stype.imm_1, fetch_i.instr.stype.imm_2};
    logic [31:0] b_imm = {
        {19{fetch_i.instr.btype.imm_1}}, fetch_i.instr.btype.imm_2, fetch_i.instr.btype.imm_3, fetch_i.instr.btype.imm_4
    };
    logic [31:0] u_imm = {fetch_i.instr.utype.imm, 12'b0};
    logic [31:0] j_imm = {
        {12{fetch_i.instr.jtype.imm_1}}, fetch_i.instr.jtype.imm_2, fetch_i.instr.jtype.imm_3, fetch_i.instr.jtype.imm_4
    };

    logic [4:0] rd = fetch_i.instr.rtype.rd;
    logic [4:0] rs1 = fetch_i.instr.rtype.rs1;
    logic [4:0] rs2 = fetch_i.instr.rtype.rs2;
    logic is_wb = (fetch_i.instr.rtype.opcode != OPCODE_STORE && fetch_i.instr.rtype.opcode != OPCODE_BRANCH) ? 1 : 0;

    always_comb begin
        decode_o.rs1 = rs1;
        decode_o.rs2 = rs2;
        decode_o.rd = rd;
        decode_o.is_wb = is_wb;
        decode_o.pc = fetch_i.pc;
    end

    // Immediate
    always_comb begin
        case (fetch_i.instr.rtype.opcode)
            OPCODE_LUI, OPCODE_AUIPC:             decode_o.imm <= u_imm;
            OPCODE_JAL:                           decode_o.imm <= j_imm;
            OPCODE_IMM, OPCODE_LOAD, OPCODE_JALR: decode_o.imm <= i_imm;
            OPCODE_STORE:                         decode_o.imm <= s_imm;
            OPCODE_BRANCH:                        decode_o.imm <= b_imm;
            default:                              decode_o.imm <= 0;
        endcase
    end

    // Instruction decoding
    always_comb begin
        decode_o.is_br = 0;
        decode_o.uses_rs2 = 0;
        case (fetch_i.instr.rtype.opcode)
            OPCODE_ALU: begin
                // verilog_format: off
                case ({fetch_i.instr.rtype.funct7, fetch_i.instr.rtype.funct3})
                    {FUNCT7_ADD,    FUNCT3_ADD}:    decode_o.op = ADD;
                    {FUNCT7_SUB,    FUNCT3_SUB}:    decode_o.op = SUB;
                    {FUNCT7_SLL,    FUNCT3_SLL}:    decode_o.op = SLL;
                    {FUNCT7_SLT,    FUNCT3_SLT}:    decode_o.op = SLT;
                    {FUNCT7_SLTU,   FUNCT3_SLTU}:   decode_o.op = SLTU;
                    {FUNCT7_XOR,    FUNCT3_XOR}:    decode_o.op = XOR;
                    {FUNCT7_SRL,    FUNCT3_SRL}:    decode_o.op = SRL;
                    {FUNCT7_SRA,    FUNCT3_SRA}:    decode_o.op = SRA;
                    {FUNCT7_OR,     FUNCT3_OR}:     decode_o.op = OR;
                    {FUNCT7_AND,    FUNCT3_AND}:    decode_o.op = AND;
                    {FUNCT7_MUL,    FUNCT3_MUL}:    decode_o.op = MUL;
                    {FUNCT7_MULH,   FUNCT3_MULH}:   decode_o.op = MULH;
                    {FUNCT7_MULHSU, FUNCT3_MULHSU}: decode_o.op = MULHSU;
                    {FUNCT7_MULHU,  FUNCT3_MULHU}:  decode_o.op = MULHU;
                    {FUNCT7_DIV,    FUNCT3_DIV}:    decode_o.op = DIV;
                    {FUNCT7_DIVU,   FUNCT3_DIVU}:   decode_o.op = DIVU;
                    {FUNCT7_REM,    FUNCT3_REM}:    decode_o.op = REM;
                    {FUNCT7_REMU,   FUNCT3_REMU}:   decode_o.op = REMU;
                endcase
                // verilog_format: on
                decode_o.uses_rs2 = 1;
            end
            OPCODE_IMM: begin
                case (fetch_i.instr.rtype.funct3)
                    FUNCT3_ADDI:  decode_o.op = ADDI;
                    FUNCT3_SLTI:  decode_o.op = SLTI;
                    FUNCT3_SLTIU: decode_o.op = SLTIU;
                    FUNCT3_XORI:  decode_o.op = XORI;
                    FUNCT3_ORI:   decode_o.op = ORI;
                    FUNCT3_ANDI:  decode_o.op = ANDI;
                    FUNCT3_SLLI:  decode_o.op = SLLI;
                    FUNCT3_SRLI, FUNCT3_SRAI: begin
                        decode_o.op = (fetch_i.instr.rtype.funct7 == FUNCT7_SRLI) ? SRLI :
                                      (fetch_i.instr.rtype.funct7 == FUNCT7_SRAI) ? SRAI : ILLEGAL;
                    end
                endcase
            end
            OPCODE_LOAD: begin
                case (fetch_i.instr.rtype.funct3)
                    FUNCT3_LB:  decode_o.op = LB;
                    FUNCT3_LH:  decode_o.op = LH;
                    FUNCT3_LW:  decode_o.op = LW;
                    FUNCT3_LBU: decode_o.op = LBU;
                    FUNCT3_LHU: decode_o.op = LHU;
                endcase
            end
            OPCODE_STORE: begin
                case (fetch_i.instr.rtype.funct3)
                    FUNCT3_SB: decode_o.op = SB;
                    FUNCT3_SH: decode_o.op = SH;
                    FUNCT3_SW: decode_o.op = SW;
                endcase
                decode_o.uses_rs2 = 1;
            end
            OPCODE_BRANCH: begin
                case (fetch_i.instr.rtype.funct3)
                    FUNCT3_BEQ:  decode_o.op = BEQ;
                    FUNCT3_BNE:  decode_o.op = BNE;
                    FUNCT3_BLT:  decode_o.op = BLT;
                    FUNCT3_BGE:  decode_o.op = BGE;
                    FUNCT3_BLTU: decode_o.op = BLTU;
                    FUNCT3_BGEU: decode_o.op = BGEU;
                endcase
                decode_o.is_br = 1;
            end
            OPCODE_JAL:   decode_o.op = JAL;
            OPCODE_JALR:  decode_o.op = JALR;
            OPCODE_LUI:   decode_o.op = LUI;
            OPCODE_AUIPC: decode_o.op = AUIPC;
            OPCODE_ECALL: begin
                case (fetch_i.instr.itype.imm)
                    IMM_ECALL:  decode_o.op = ECALL;
                    IMM_EBREAK: decode_o.op = EBREAK;
                endcase
            end
            // TODO: Throw exception on default
        endcase
    end

    // Regfile access (in parallel to decoding)
    regfile #(
        .NUMREGS  (RF_NUMREGS),
        .DATAWIDTH(XLEN)
    ) regfile (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .re_a_i   (1),
        .rdata_a_o(decode_o.data_rs1),
        .raddr_a_i(rs1),
        .re_b_i   (1),
        .rdata_b_o(decode_o.data_rs2),
        .raddr_b_i(rs2),
        .we_i     (from_wb_i.is_wb),
        .wdata_i  (from_wb_i.data),
        .waddr_i  (from_wb_i.rd)
    );

endmodule
