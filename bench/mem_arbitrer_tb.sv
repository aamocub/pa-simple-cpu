`include "riscv_pkg.sv"
`include "pa_pkg.sv"

module mem_arbitrer_tb
    import pa_pkg::*;
    import riscv_pkg::*;
();

    parameter integer CLK_PERIOD = 20;

    reg              clk;
    reg              rst;

    if_req_t         if_req_i;
    if_resp_t        if_resp_o;
    mm_read_req_t    mm_read_req_i;
    mm_read_resp_t   mm_read_resp_o;
    mm_write_req_t   mm_write_req_i;
    mm_write_resp_t  mm_write_resp_o;

    mem_read_req_t   readreq;
    mem_read_resp_t  readresp;
    mem_write_req_t  writereq;
    mem_write_resp_t writeresp;

    always #(CLK_PERIOD / 2) clk <= ~clk;

    mem_arbitrer arbitrer (
        .clk_i(clk),
        .rst_i(rst),
        .if_req_i(if_req_i),
        .if_resp_o(if_resp_o),
        .mm_read_req_i(mm_read_req_i),
        .mm_read_resp_o(mm_read_resp_o),
        .mm_write_req_i(mm_write_req_i),
        .mm_write_resp_o(mm_write_resp_o),
        .mem_read_req_o(readreq),
        .mem_read_resp_i(readresp),
        .mem_write_req_o(writereq),
        .mem_write_resp_i(writeresp)
    );

    memory #() memory (
        .clk_i  (clk),
        .rst_i  (rst),
        .read_i (readreq),
        .read_o (readresp),
        .write_i(writereq),
        .write_o(writeresp)
    );

    initial begin
        $dumpfile("mem_arbitrer_tb.fst");
        $dumpvars(0, mem_arbitrer_tb);
        clk = 1;
        rst = 1;
        #CLK_PERIOD rst = 0;
        if_req_i.valid = 1;
        if_req_i.addr = 2;
        mm_read_req_i.valid = 1;
        mm_read_req_i.addr = 4;
        mm_write_req_i.valid = 1;
        mm_write_req_i.addr = 5;
        mm_write_req_i.data = 99;
        #(CLK_PERIOD * 20);
        $finish();
    end

endmodule
