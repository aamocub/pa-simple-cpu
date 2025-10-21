`define ADD_OP  4'b0000
`define LW_OP   4'b0001
`define SW_OP   4'b0010
`define SUB_OP  4'b0011
`define MUL_OP  4'b0100
`define DIV_OP  4'b0101
`define AND_OP  4'b0110
`define OR_OP   4'b0111
`define XOR_OP  4'b1000
`define BEQ_OP  4'b1001
`define BGT_OP  4'b1010
`define BGE_OP  4'b1011
`define JMP_OP  4'b1100
`define LI_OP   4'b1101

// First invalid OP
`define LAST_OP 4'b1110