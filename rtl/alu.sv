module alu
    import pa_pkg::*;
    import riscv_pkg::*;
#(
    localparam MUL_DELAY = 5
) (
    input  logic      [XLEN-1:0] a_i,
    input  logic      [XLEN-1:0] b_i,
    input  instr_op_t            opcode_i,
    output logic      [XLEN-1:0] out_o,
    output logic                 stall_o
);

    logic [           XLEN*2-1:0] mul_tmp;  // mul intermediate result
    logic [             XLEN-1:0] mul_res;  // mul result
    logic [$clog2(MUL_DELAY)-1:0] mul_delay;  // mul delay counter register

    always_comb begin
        stall_o = 0;  // Do not stall by default

        if (mul_delay == MUL_DELAY - 1) begin
            out_o = mul_tmp[XLEN-1:0];
            mul_delay = 0;
        end else if (mul_delay > 0) begin
            stall_o = 1;
            mul_delay++;
        end else begin
            case (opcode_i)
                ADD, ADDI: out_o = a_i + b_i;
                SUB:       out_o = a_i - b_i;
                XOR, XORI: out_o = a_i ^ b_i;
                OR, ORI:   out_o = a_i | b_i;
                AND, ANDI: out_o = a_i & b_i;

                // Shifts
                SLL, SLLI: out_o = a_i << b_i[4:0];  // shift left logical
                SRL, SRLI: out_o = a_i >> b_i[4:0];  // shift right logical
                SRA, SRAI: out_o = $signed(a_i) >>> b_i[4:0];  // shift right arithmetic

                // Comparisons
                SLT, SLTI:   out_o = ($signed(a_i) < $signed(b_i)) ? 'b1 : 'b0;  // signed less than
                SLTU, SLTIU: out_o = (a_i < b_i) ? 'b1 : 'b0;  // unsigned less than

                // Multiplication
                MUL: begin  // low XLEN bits
                    mul_tmp = a_i * b_i;
                    mul_res = mul_tmp[XLEN-1:0];
                    stall_o = 1;
                    mul_delay++;
                end
                MULH: begin  // high XLEN bits (signed * signed)
                    mul_tmp = $signed(a_i) * $signed(b_i);
                    mul_res = mul_tmp[2*XLEN-1:XLEN];
                    stall_o = 1;
                    mul_delay++;
                end
                MULHSU: begin  // high XLEN bits (signed * unsigned)
                    mul_tmp = $signed(a_i) * $unsigned(b_i);
                    mul_res = mul_tmp[2*XLEN-1:XLEN];
                    stall_o = 1;
                    mul_delay++;
                end
                MULHU: begin  // high XLEN bits (unsigned * unsigned)
                    mul_tmp = $unsigned(a_i) * $unsigned(b_i);
                    mul_res = mul_tmp[2*XLEN-1:XLEN];
                    stall_o = 1;
                    mul_delay++;
                end

                // Division / Remainder
                // TODO: Exceptions on div by 0
                DIV:  out_o = (b_i == 0) ? 'x : $signed(a_i) / $signed(b_i);
                DIVU: out_o = (b_i == 0) ? 'x : a_i / b_i;
                REM:  out_o = (b_i == 0) ? 'x : $signed(a_i) % $signed(b_i);
                REMU: out_o = (b_i == 0) ? 'x : a_i % b_i;

                // Branches
                BEQ, BNE, BLT, BGE, BLTU, BGEU: out_o = a_i + b_i;

                default: out_o = 'x;
            endcase
        end
    end

endmodule
