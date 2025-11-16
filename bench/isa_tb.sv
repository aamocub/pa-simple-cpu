
module isa_tb
    import riscv_pkg::*;
    import pa_pkg::*;
();
    pa_pkg::mem_read_req_t readreq;
    pa_pkg::mem_read_resp_t readresp;
    pa_pkg::mem_write_req_t writereq;
    pa_pkg::mem_write_resp_t writeresp;

    logic clk_i;
    logic rst_i;
    localparam CLK_PERIOD = 20;
    always #(CLK_PERIOD / 2) clk_i <= ~clk_i;

    core #(
        .DEBUG(0)
    ) core (
        .clk_i     (clk_i),
        .rst_i     (rst_i),
        .read_req  (readreq),
        .read_resp (readresp),
        .write_req (writereq),
        .write_resp(writeresp)
    );

    memory #(
        .DEBUG(1)
    ) memory (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .read_i (readreq),
        .read_o (readresp),
        .write_i(writereq),
        .write_o(writeresp)
    );

    initial begin
        $dumpfile("isa_tb.fst");
        $dumpvars(0, isa_tb);
        clk_i = 1;
        rst_i = 1;
        #(CLK_PERIOD) rst_i = 0;
        #(CLK_PERIOD * 20);
        $finish();
    end

endmodule
