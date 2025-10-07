`include "opcode.svh"

module alu #(
    parameter integer DATAWIDTH = 32
) (
    input logic [DATAWIDTH-1:0] a_i,
    input logic [DATAWIDTH-1:0] b_i,
    input logic [3:0] opcode_i,
    output logic [DATAWIDTH-1:0] out_o
);

    always_comb
        case (opcode_i)
            `ADD_OP: out_o = a_i + b_i;
            `LW_OP:  out_o = a_i + b_i;
            `SW_OP:  out_o = a_i + b_i;
            `SUB_OP: out_o = a_i - b_i;
            `MUL_OP: out_o = a_i * b_i;
            `DIV_OP: out_o = a_i / b_i;
            `AND_OP: out_o = a_i & b_i;
            `OR_OP:  out_o = a_i | b_i;
            `XOR_OP: out_o = a_i ^ b_i;
            `BEQ_OP: out_o = a_i + b_i;
            `BGT_OP: out_o = a_i + b_i;
            `BGE_OP: out_o = a_i + b_i;
            `JMP_OP: out_o = a_i + b_i;
            `LI_OP:  out_o = a_i + b_i;
            default: out_o = 'x;
        endcase

endmodule
