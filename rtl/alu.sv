module alu
    import pa_pkg::*;
    import riscv_pkg::*;
#(
    localparam MUL_DELAY = 5
) (
    input  logic                 clk_i,
    input  logic                 rst_i,
    input  logic      [XLEN-1:0] a_i,
    input  logic      [XLEN-1:0] b_i,
    input  instr_op_t            opcode_i,
    output logic      [XLEN-1:0] out_o,
    output logic                 stall_o,
    output logic                 div_zero_o
);

    logic [           XLEN*2-1:0] mul_tmp;  // mul intermediate result
    logic [$clog2(MUL_DELAY)-1:0] mul_delay;  // mul delay counter register

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            mul_delay <= 0;
        end else begin
            if (mul_delay == MUL_DELAY - 1) begin
                mul_delay <= 0;
            end else if (mul_delay > 0) begin
                mul_delay <= mul_delay + 1;
            end else begin
                case (opcode_i)
                    MUL, MULH, MULHSU, MULHU: mul_delay <= mul_delay + 1;
                    default: ;
                endcase
            end
        end
    end

    always_comb begin
        div_zero_o = 0;
        stall_o = 0;  // Do not stall by default
        out_o = '0;
        unique case (opcode_i)
            NOP: out_o = '0;

            // Add / Sub
            ADD, ADDI: out_o = a_i + b_i;
            SUB:       out_o = a_i - b_i;

            LUI: out_o = b_i;
            AUIPC: out_o = a_i + b_i;
            ECALL, EBREAK, ILLEGAL: out_o = '0;

            // Logic
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
                out_o   = mul_tmp[XLEN-1:0];
                if (mul_delay < MUL_DELAY - 1) stall_o = 1;
            end
            MULH: begin  // high XLEN bits (signed * signed)
                mul_tmp = $signed(a_i) * $signed(b_i);
                out_o   = mul_tmp[XLEN*2-1:XLEN];
                if (mul_delay < MUL_DELAY - 1) stall_o = 1;
            end
            MULHSU: begin  // high XLEN bits (signed * unsigned)
                mul_tmp = $signed(a_i) * $unsigned(b_i);
                out_o   = mul_tmp[XLEN*2-1:XLEN];
                if (mul_delay < MUL_DELAY - 1) stall_o = 1;
            end
            MULHU: begin  // high XLEN bits (unsigned * unsigned)
                mul_tmp = $unsigned(a_i) * $unsigned(b_i);
                out_o   = mul_tmp[XLEN*2-1:XLEN];
                if (mul_delay < MUL_DELAY - 1) stall_o = 1;
            end

            // Division / Remainder
            DIV: begin
                div_zero_o = (b_i == 0) ? 1 : 0;
                out_o = (b_i == 0) ? 'x : $signed(a_i) / $signed(b_i);
            end
            DIVU: begin
                div_zero_o = (b_i == 0) ? 1 : 0;
                out_o = (b_i == 0) ? 'x : a_i / b_i;
            end
            REM: begin
                div_zero_o = (b_i == 0) ? 1 : 0;
                out_o = (b_i == 0) ? 'x : $signed(a_i) % $signed(b_i);
            end
            REMU: begin
                div_zero_o = (b_i == 0) ? 1 : 0;
                out_o = (b_i == 0) ? 'x : a_i % b_i;
            end

            // Branches
            BEQ, BNE, BLT, BGE, BLTU, BGEU: out_o = a_i + b_i;

            // Jumps
            JAL, JALR: out_o = a_i + b_i;

            // Load / Store
            LB, LH, LW, LBU, LHU, SB, SH, SW: out_o = a_i + b_i;

            // default: out_o = 'x;
        endcase
    end

endmodule
