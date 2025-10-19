
// Instruction Encoding - 32-bits
// ________________________________________________________________
// | offset[31:19] | ra[18:14] | rb[13:9] | rd[8:4] | opcode[3:0] |
// ----------------------------------------------------------------

`include "opcode.svh"

module decoder (
    input wire [31:0] instr_i,

    output wire [31:19] offset_o,
    output wire [18:14] ra_o,
    output wire [ 13:9] rb_o,
    output wire [  8:4] rd_o,
    output wire [  3:0] opcode_o,
    output wire         exception_o
);

    assign offset_o = instr_i[31:19];
    assign ra_o = instr_i[18:14];
    assign rb_o = instr_i[13:9];
    assign rd_o = instr_i[8:4];
    assign opcode_o = instr_i[3:0];

    assign exception_o = (opcode_o < `LAST_OP) ? 0 : 1;

endmodule
