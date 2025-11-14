module top
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input clk_i,
    input rst_i
);
    pa_pkg::mem_read_req_t   readreq;
    pa_pkg::mem_read_resp_t  readresp;
    pa_pkg::mem_write_req_t  writereq;
    pa_pkg::mem_write_resp_t writeresp;

    core #(
        .DEBUG(0)
    ) core (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .read_req(readreq),
        .read_resp(readresp),
        .write_req(writereq),
        .write_resp(writeresp)
    );

    memory #() memory (
        .clk_i  (clk_i),
        .rst_i  (rst_i),
        .read_i (readreq),
        .read_o (readresp),
        .write_i(writereq),
        .write_o(writeresp)
    );
endmodule
