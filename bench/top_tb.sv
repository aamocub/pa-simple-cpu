// Instruction Encoding - 32-bits
// ________________________________________________________________
// | offset[31:19] | ra[18:14] | rb[13:9] | rd[8:4] | opcode[3:0] |
// ----------------------------------------------------------------
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

`define ALU(ra, rb, rd, op) {{13{1'b0}}, (ra), (rb), (rd), (op)}
`define MEM(off, ra, rb, op) {(off), (ra), (rb), 5'b00000, (op)}
`define JMP(off, ra, rb, op) {(off), (ra), (rb), 5'b00000, (op)}

module top_tb ();

reg [31:0] add_instr = `ALU(5'b00001, 5'b00001, 5'b00011, `SW_OP);
reg [31:0] lw_instr = `MEM(13'd420, 5'b00000, 5'b00100, 4'b0010);
reg [31:0] jmp_instr = `JMP(13'd420, 5'b00100, 5'b00100, `BEQ_OP);

parameter integer CLK_PERIOD = 20;

reg clk;
reg rst;

always #(CLK_PERIOD/2) clk = ~clk;

top#(
        .DATAWIDTH(32),
        .DEBUG(1)
) top (
        .clk_i(clk),
        .rst_i(rst),
        .instr_debug_i(jmp_instr)
);

initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);
        clk = 1;
        rst = 1;
        #10
        rst = 0;
        #20
        $finish();
end

endmodule