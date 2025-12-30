`define RINST(f7, rs2, rs1, f3, rd, opcode) {f7, rs2, rs1, f3, rd, opcode}
`define IINST(imm, rs1, f3, rd, opcode) {imm, rs1, f3, rd, opcode}
`define SINST(imm, rs2, rs1, f3, opcode) {imm[11:5], rs2, rs1, f3, imm[4:0], opcode}
`define BINST(imm, rs2, rs1, f3,
              opcode) {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], opcode}
`define LINST(imm, rs1, f3, rd, opcode) {imm, rs1, f3, rd, opcode}

module cache_tb
    import riscv_pkg::*;
    import pa_pkg::*;
();
    logic [11:0] soffset = 12'h200;  // interpreted as a multiple of 2 bytes

    logic [31:0] lw1 = `LINST(12'h200, 5'd0, riscv_pkg::FUNCT3_LW, 5'd29, riscv_pkg::OPCODE_LOAD);
    logic [31:0] lw2 = `LINST(12'h204, 5'd0, riscv_pkg::FUNCT3_LW, 5'd29, riscv_pkg::OPCODE_LOAD);
    logic [31:0] lw3 = `LINST(12'h208, 5'd0, riscv_pkg::FUNCT3_LW, 5'd29, riscv_pkg::OPCODE_LOAD);
    logic [31:0] lw4 = `LINST(12'h20C, 5'd0, riscv_pkg::FUNCT3_LW, 5'd29, riscv_pkg::OPCODE_LOAD);
    logic [31:0] lw5 = `LINST(12'h100, 5'd0, riscv_pkg::FUNCT3_LW, 5'd29, riscv_pkg::OPCODE_LOAD);
    logic [31:0] sw = `SINST(soffset, 5'd28, 5'd0, riscv_pkg::FUNCT3_SW, riscv_pkg::OPCODE_STORE);
    logic [31:0] instr_list[3] = {lw1, sw, lw5};
    /*
    logic [31:0] add1 = `RINST(riscv_pkg::FUNCT7_ADD, 5'd2, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd1, riscv_pkg::OPCODE_ALU);
    logic [31:0] add2 = `RINST(riscv_pkg::FUNCT7_ADD, 5'd3, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd1, riscv_pkg::OPCODE_ALU);
    logic [31:0] add3 = `RINST(riscv_pkg::FUNCT7_ADD, 5'd4, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd1, riscv_pkg::OPCODE_ALU);
    logic [31:0] instr_list[5] = {add1, add2, add3, add3, add3};
    */

    logic clk_i;
    logic rst_i;
    localparam CLK_PERIOD = 20;
    always #(CLK_PERIOD / 2) clk_i <= ~clk_i;

    top #() top (
        .clk_i(clk_i),
        .rst_i(rst_i)
    );

    initial begin
        $dumpfile("cache_tb.fst");
        $dumpvars(0, cache_tb);
        for (int j = 0; j < 64 / 4; j = j + 1) begin
            // memory.mem[4*j+:4] = {>>{j}};
        end
        for (int i = 0; i < $size(instr_list); i = i + 1) begin
            top.memory.mem[PC_RESET_ADDR+4*i+:4] = {>>{instr_list[i]}};
        end
        clk_i = 1;
        rst_i = 1;
        #(CLK_PERIOD) rst_i = 0;
        #(CLK_PERIOD * 100);
        $finish();
    end

endmodule
