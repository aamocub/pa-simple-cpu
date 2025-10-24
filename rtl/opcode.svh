`define NOP_OP  4'b0000
`define ADD_OP  4'b0001
`define LW_OP   4'b0010
`define SW_OP   4'b0011
`define SUB_OP  4'b0100
`define MUL_OP  4'b0101
`define DIV_OP  4'b0110
`define AND_OP  4'b0111
`define OR_OP   4'b1000
`define XOR_OP  4'b1001
`define BEQ_OP  4'b1010
`define BGT_OP  4'b1011
`define BGE_OP  4'b1100
`define JMP_OP  4'b1101
`define ADDI_OP 4'b1110

// First invalid OP
`define LAST_OP 4'b1111
