module cmp
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input logic [XLEN-1:0] a_i,
    input logic [XLEN-1:0] b_i,
    input instr_op_t op_i,
    output logic out_o
);

    always_comb begin
        case (op_i)
            JAL:     out_o = 1;
            JALR:    out_o = 1;
            BEQ:     out_o = ($signed(a_i) == $signed(b_i)) ? 1 : 0;
            BNE:     out_o = ($signed(a_i) != $signed(b_i)) ? 1 : 0;
            BLT:     out_o = ($signed(a_i) < $signed(b_i)) ? 1 : 0;
            BGE:     out_o = ($signed(a_i) >= $signed(b_i)) ? 1 : 0;
            BLTU:    out_o = (a_i < b_i) ? 1 : 0;
            BGEU:    out_o = (a_i >= b_i) ? 1 : 0;
            default: out_o = 0;
        endcase
    end
endmodule
