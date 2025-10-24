// Instruction Encoding - 32-bits
// ________________________________________________________________
// | offset[31:19] | ra[18:14] | rb[13:9] | rd[8:4] | opcode[3:0] |
// ----------------------------------------------------------------
`include "opcode.svh"

`define ALU(ra, rb, rd, op)   {{13{1'b0}}, (ra), (rb), (rd), (op)}
`define ALUI(off, ra, rd, op) {(off), (ra), 5'b0, (rd), (op)}
`define MEM(off, ra, rb, op)  {(off), (ra), (rb), 5'b00000, (op)}
`define JMP(off, ra, rb, op)  {(off), (ra), (rb), 5'b00000, (op)}

module top_tb ();

reg [31:0] add_instr = `ALU(5'b00001, 5'b00001, 5'b00011, `ADD_OP);
reg [31:0] add_instr2 = `ALU(5'b00001, 5'b00011, 5'b10110, `ADD_OP);
reg [31:0] add_instr3 = `ALU(5'b00001, 5'b10110, 5'b10111, `ADD_OP);
reg [31:0] sub_instr = `ALU(5'b00011, 5'b00100, 5'b00101, `SUB_OP);
reg [31:0] mul_instr = `ALU(5'b00110, 5'b00111, 5'b01000, `MUL_OP);
reg [31:0] div_instr = `ALU(5'b01001, 5'b01010, 5'b01011, `DIV_OP);
reg [31:0] and_instr = `ALU(5'b01100, 5'b01110, 5'b01111, `AND_OP);
reg [31:0] or_instr  = `ALU(5'b10000, 5'b10001, 5'b10010, `OR_OP);
reg [31:0] xor_instr = `ALU(5'b10011, 5'b10100, 5'b10101, `XOR_OP);
reg [31:0] addi_instr = `ALUI(13'd69, 5'b00000, 5'b00001, `ADDI_OP);

reg [31:0] lw_instr = `MEM(13'd15, 5'b00000, 5'b00100, `LW_OP);
reg [31:0] sw_instr = `MEM(13'd16, 5'b00000, 5'b00111, `SW_OP);

reg [31:0] beq_instr = `JMP(13'd15, 5'b00100, 5'b00100, `BEQ_OP);
reg [31:0] bgt_instr = `JMP(13'd16, 5'b00100, 5'b00100, `BGT_OP);
reg [31:0] bge_instr = `JMP(13'd17, 5'b00100, 5'b00100, `BGE_OP);

reg [31:0] instr_list [15] = {add_instr, add_instr2, add_instr3, sub_instr, mul_instr, div_instr, and_instr, or_instr, xor_instr, addi_instr, lw_instr, sw_instr, beq_instr, bgt_instr, bge_instr};

parameter integer CLK_PERIOD = 20;

reg [31:0] current_instr;

reg clk;
reg rst;

always #(CLK_PERIOD/2) clk = ~clk;

top#(
        .DATAWIDTH(32),
        .DEBUG(1)
) top (
        .clk_i(clk),
        .rst_i(rst),
        .instr_debug_i(current_instr)
);

integer i;

initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);
        clk = 1;
        rst = 1;
        #CLK_PERIOD rst = 0;
        for (i = 0; i < 14; i = i+1) begin
                #CLK_PERIOD current_instr = instr_list[i];
        end
        $finish();
end

endmodule