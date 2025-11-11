`include "../rtl/riscv_pkg.sv"
`include "../rtl/pa_pkg.sv"

module if_stage_tb
    import riscv_pkg::*;
    import pa_pkg::*;
();
    localparam CLK_PERIOD = 20;

    logic clk;
    logic rst;

    cu_if_t ctrl = '{default: 0};
    if_req_t req;
    if_resp_t resp;
    if_stage_t ifout;

    if_stage if_stage (
        .clk_i (clk),
        .rst_i (rst),
        .ctrl_i(ctrl),
        .req_o (req),
        .resp_i(resp),
        .if_o  (ifout)
    );

    always #(CLK_PERIOD / 2) clk <= ~clk;
    initial begin
        $dumpfile("if_stage_tb.vcd");
        $dumpvars(0, if_stage_tb);
        clk = 1;
        rst = 1;

        #CLK_PERIOD rst = 0;

        #CLK_PERIOD;
        resp.valid = 1;
        resp.data  = NOP_INSTR;
        #CLK_PERIOD;

        #(CLK_PERIOD * 10);

        $finish();
    end

endmodule
