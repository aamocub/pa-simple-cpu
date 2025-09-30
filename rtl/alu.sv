module alu #(
    parameter integer DATAWIDTH = 32
) (
    input  logic [DATAWIDTH-1:0] a_i,
    input  logic [DATAWIDTH-1:0] b_i,
    input  logic [3:0] opcode_i,
    output logic [DATAWIDTH-1:0] out_o
);

    always_comb
        case (opcode_i)
            4'b0000: out_o = a_i + b_i;  // add
            4'b0001: out_o = a_i + b_i;  // lw
            4'b0010: out_o = a_i + b_i;  // sw
            4'b0011: out_o = a_i - b_i;  // sub
            4'b0100: out_o = a_i * b_i;  // mul
            4'b0101: out_o = a_i / b_i;  // div
            4'b0110: out_o = a_i & b_i;  // and
            4'b0111: out_o = a_i | b_i;  // or
            4'b1000: out_o = a_i ^ b_i;  // xor
            default: out_o = 'x;
        endcase

endmodule