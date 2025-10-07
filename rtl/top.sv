`include "opcode.svh"

module top #(
    parameter integer DATAWIDTH = 32
) (
    input wire clk_i,
    input wire rst_i
);

    wire [31:0] F_pc;
    wire [31:0] F_inst;

    wire [12:0] D_offset;
    wire [ 4:0] D_ra;
    wire [ 4:0] D_rb;
    wire [ 4:0] D_rd;
    wire [ 3:0] D_opcode;
    wire [31:0] D_a;
    wire [31:0] D_b;
    wire [31:0] D_imm;

    wire [31:0] X_d;

    wire [31:0] M_d;

    assign D_imm = {{19{D_offset[12]}}, D_offset[11:0]};  // Sign extend

    register #(
        .DATAWIDTH(32)
    ) pcreg (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .en_i (1),
        .d_i  (F_pc + 4),
        .q_o  (F_pc)
    );

    memory #(
        .NUMWORDS (4096),
        .DATAWIDTH(DATAWIDTH)
    ) imem (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .re_i   (1),
        .rdata_o(F_inst),
        .raddr_i(F_pc),
        .we_i   (0),
        .wdata_i(0),
        .waddr_i(0)
    );

    decoder #() decoder (
        .instr_i (F_inst),
        .offset_o(D_offset),
        .ra_o    (D_ra),
        .rb_o    (D_rb),
        .rd_o    (D_rd),
        .opcode_o(D_opcode)
    );

    memory #(
        .NUMWORDS (4096),
        .DATAWIDTH(DATAWIDTH)
    ) dmem (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .re_i   (1),
        .rdata_o(M_d),
        .raddr_i(X_d),
        .we_i   ((D_opcode == `SW_OP) ? 1 : 0),
        .wdata_i(D_b),
        .waddr_i(X_d)
    );

    regbank #(
        .NUMREGS  (32),
        .DATAWIDTH(DATAWIDTH)
    ) regbank (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .re_a_i   (1),
        .rdata_a_o(D_a),
        .raddr_a_i(D_ra),
        .re_b_i   (1),
        .rdata_b_o(D_b),
        .raddr_b_i(D_rb),
        .we_i     (1),
        .wdata_i  ((D_opcode == `LW_OP) ? M_d : X_d),
        .waddr_i  (D_rd)
    );

    alu #(
        .DATAWIDTH(32)
    ) alu (
        .a_i     (D_a),
        .b_i     ((D_opcode == `LW_OP || D_opcode == `SW_OP) ? D_imm : D_b),
        .opcode_i(D_opcode),
        .out_o   (X_d)
    );

    cmp #(
        .DATAWIDTH(32)
    ) cmp (
        .a_i  (D_a),
        .b_i  (D_b),
        .op_i (),
        .out_o()
    );


endmodule
