
// Instruction Encoding - 32-bits
// ________________________________________________________________
// | offset[31:21] | ra[20:15] | rb[14:9] | rd[8:4] | opcode[3:0] |
// ----------------------------------------------------------------

module decoder (
    input logic [31:0] instr_i,

    output logic [31:21] offset_o,
    output logic [20:15] ra_o,
    output logic [ 14:9] rb_o,
    output logic [  8:4] rd_o,
    output logic [  3:0] opcode_o
);

    assign offset_o = instr_i[31:21];
    assign ra_o     = instr_i[20:15];
    assign rb_o     = instr_i[14:9];
    assign rd_o     = instr_i[8:4];
    assign opcode_o = instr_i[3:0];

endmodule
