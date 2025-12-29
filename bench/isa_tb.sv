`define RINST(f7, rs2, rs1, f3, rd, opcode) {f7, rs2, rs1, f3, rd, opcode}
`define IINST(imm, rs1, f3, rd, opcode) {imm, rs1, f3, rd, opcode}
`define SINST(imm, rs2, rs1, f3, opcode) {imm[11:5], rs2, rs1, f3, imm[4:0], opcode}
`define BINST(imm, rs2, rs1, f3, opcode) {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], opcode}
`define LINST(imm, rs1, f3, rd, opcode) {imm, rs1, f3, rd, opcode}

module isa_tb
    import riscv_pkg::*;
    import pa_pkg::*;
();
    logic [12:1] joffset = -12'd6;  // interpreted as a multiple of 2 bytes
    logic [11:0] soffset = 12'd0;  // interpreted as a multiple of 2 bytes

    logic [31:0] add = `RINST(riscv_pkg::FUNCT7_ADD, 5'd1, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd31, riscv_pkg::OPCODE_ALU);
    logic [31:0] sub = `RINST(riscv_pkg::FUNCT7_SUB, 5'd2, 5'd2, riscv_pkg::FUNCT3_SUB, 5'd30, riscv_pkg::OPCODE_ALU);
    logic [31:0] addi = `IINST(12'd5, 5'd1, riscv_pkg::FUNCT3_ADDI, 5'd31, riscv_pkg::OPCODE_IMM);
    logic [31:0] beq = `BINST(joffset, 5'd1, 5'd1, riscv_pkg::FUNCT3_BEQ, riscv_pkg::OPCODE_BRANCH);
    logic [31:0] mul = `RINST(riscv_pkg::FUNCT7_MUL, 5'd6, 5'd9, riscv_pkg::FUNCT3_MUL, 5'd31, riscv_pkg::OPCODE_ALU);
    logic [31:0] lw = `LINST(12'd0, 5'd0, riscv_pkg::FUNCT3_LW, 5'd29, riscv_pkg::OPCODE_LOAD);
    logic [31:0] sw = `SINST(soffset, 5'd28, 5'd0, riscv_pkg::FUNCT3_SW, riscv_pkg::OPCODE_STORE);
    logic [31:0] instr_list[10] = {add, mul, sub, addi, sub, lw, sw, addi, mul, mul};
    /*
    logic [31:0] add1 = `RINST(riscv_pkg::FUNCT7_ADD, 5'd2, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd1, riscv_pkg::OPCODE_ALU);
    logic [31:0] add2 = `RINST(riscv_pkg::FUNCT7_ADD, 5'd3, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd1, riscv_pkg::OPCODE_ALU);
    logic [31:0] add3 = `RINST(riscv_pkg::FUNCT7_ADD, 5'd4, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd1, riscv_pkg::OPCODE_ALU);
    logic [31:0] instr_list[5] = {add1, add2, add3, add3, add3};
    */

    memory_intf #(.DATA_WIDTH(128)) mem_a_io ();
    memory_intf #(.DATA_WIDTH(128)) mem_b_io ();

    logic clk_i;
    logic rst_i;
    localparam CLK_PERIOD = 20;
    always #(CLK_PERIOD / 2) clk_i <= ~clk_i;

    core #(
        .DEBUG(0)
    ) core (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .mem_a_io(mem_a_io.CL),
        .mem_b_io(mem_b_io.CL)
    );

    memory #(
        .NUMWORDS(64)
    ) memory (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .mem_a_io(mem_a_io.SV),
        .mem_b_io(mem_b_io.SV)
    );

    initial begin
        $dumpfile("isa_tb.fst");
        $dumpvars(0, isa_tb);
        for (int j = 0; j < 64 / 4; j = j + 1) begin
            memory.mem[4*j+:4] = {>>{j}};
        end
        for (int i = 0; i < $size(instr_list); i = i + 1) begin
            memory.mem[PC_RESET_ADDR+4*i+:4] = {>>{instr_list[i]}};
        end
        clk_i = 1;
        rst_i = 1;
        #(CLK_PERIOD) rst_i = 0;
        #(CLK_PERIOD * 100);
        $finish();
    end

endmodule
