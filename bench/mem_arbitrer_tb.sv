`include "riscv_pkg.sv"
`include "pa_pkg.sv"

module mem_arbitrer_tb
    import pa_pkg::*;
    import riscv_pkg::*;
();
    /*
    parameter integer CLK_PERIOD = 20;

    reg       clk;
    reg       rst;

    if_req_t  if_req_i;
    if_resp_t if_resp_o;

    memory_intf cc_io ();
    memory_intf mem_io ();

    always #(CLK_PERIOD / 2) clk <= ~clk;

    mem_arbitrer arbitrer (
        .clk_i(clk),
        .rst_i(rst),
        .if_req_i(if_req_i),
        .if_resp_o(if_resp_o),
        .cache_io(cc_io.SV),
        .mem_io(mem_io.CL)
    );

    memory memory (
        .clk_i (clk),
        .rst_i (rst),
        .mem_io(mem_io.SV)
    );

    initial begin
        $dumpfile("mem_arbitrer_tb.fst");
        $dumpvars(0, mem_arbitrer_tb);
        clk = 1;
        rst = 1;
        #CLK_PERIOD rst = 0;
        if_req_i.valid = 1;
        if_req_i.addr = 2;
        cc_io.read_req.valid = 1;
        cc_io.read_req.addr = 4;
        cc_io.write_req.valid = 1;
        cc_io.write_req.addr = 5;
        cc_io.write_req.data = 99;
        #(CLK_PERIOD * 20);
        $finish();
    end
*/
endmodule
