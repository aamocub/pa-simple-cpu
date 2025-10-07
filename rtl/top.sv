module top #(
    parameter integer DATAWIDTH = 32
) (
    input wire clk_i,
    input wire rst_i
);
    register #(
        .DATAWIDTH(32)
    ) pc (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .en_i (),
        .d_i  (),
        .q_o  ()
    );

    memory #(
        .NUMWORDS (4096),
        .DATAWIDTH(DATAWIDTH)
    ) imem (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .re_i   (),
        .rdata_o(),
        .raddr_i(),
        .we_i   (),
        .wdata_i(),
        .waddr_i()
    );

    memory #(
        .NUMWORDS (4096),
        .DATAWIDTH(DATAWIDTH)
    ) dmem (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .re_i   (),
        .rdata_o(),
        .raddr_i(),
        .we_i   (),
        .wdata_i(),
        .waddr_i()
    );

    regbank #(
        .NUMREGS  (32),
        .DATAWIDTH(DATAWIDTH)
    ) regbank (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .re_a_i   (),
        .rdata_a_o(),
        .raddr_a_i(),
        .re_b_i   (),
        .rdata_b_o(),
        .raddr_b_i(),
        .we_i     (),
        .wdata_i  (),
        .waddr_i  ()
    );

    alu #(
        .DATAWIDTH(32)
    ) alu (
        .a_i     (),
        .b_i     (),
        .opcode_i(),
        .out_o   ()
    );

    cmp #(
        .DATAWIDTH(32)
    ) cmp (
        .a_i (),
        .b_i (),
        .eq_o(),
        .gt_o(),
        .lt_o()
    );


endmodule
