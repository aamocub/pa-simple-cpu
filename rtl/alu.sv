`include "opcode.svh"

module alu
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input  logic      [XLEN-1:0] a_i,
    input  logic      [XLEN-1:0] b_i,
    input  instr_op_t            opcode_i,
    output logic      [XLEN-1:0] out_o
);

    logic [XLEN*2-1:0] mul_tmp;

    always_comb
        case (opcode_i)
            ADD, ADDI: out_o = a_i + b_i;
            SUB:       out_o = a_i - b_i;
            XOR, XORI: out_o = a_i ^ b_i;
            OR, ORI:   out_o = a_i | b_i;
            AND, ANDI: out_o = a_i & b_i;

            // Shifts
            SLL, SLLI:   out_o = a_i << b_i[4:0];  // shift left logical
            SLT, SLTI:   out_o = ($signed(a_i) < $signed(b_i)) ? 32'd1 : 32'd0;  // signed less than
            SLTU, SLTIU: out_o = (a_i < b_i) ? 32'd1 : 32'd0;  // unsigned less than
            SRL, SRLI:   out_o = a_i >> b_i[4:0];  // shift right logical
            SRA, SRAI:   out_o = $signed(a_i) >>> b_i[4:0];  // shift right arithmetic

            // Multiplication
            MUL: begin
                mul_tmp = a_i * b_i;
                out_o   = mul_tmp[XLEN-1:0];  // low XLEN bits
            end
            MULH: begin
                mul_tmp = $signed(a_i) * $signed(b_i);
                out_o   = mul_tmp[2*XLEN-1:XLEN];  // high XLEN bits (signed * signed)
            end
            MULHSU: begin
                mul_tmp = $signed(a_i) * $unsigned(b_i);
                out_o   = mul_tmp[2*XLEN-1:XLEN];  // high XLEN bits (signed * unsigned)
            end
            MULHU: begin
                mul_tmp = $unsigned(a_i) * $unsigned(b_i);
                out_o   = mul_tmp[2*XLEN-1:XLEN];  // high XLEN bits (unsigned * unsigned)
            end

            // Division / Remainder
            // TODO: Exceptions on div by 0
            DIV:  out_o = (b_i == 0) ? 'x : $signed(a_i) / $signed(b_i);
            DIVU: out_o = (b_i == 0) ? 'x : a_i / b_i;
            REM:  out_o = (b_i == 0) ? 'x : $signed(a_i) % $signed(b_i);
            REMU: out_o = (b_i == 0) ? 'x : a_i % b_i;

            default: out_o = 'x;
        endcase

endmodule
