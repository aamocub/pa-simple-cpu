`include "riscv_pkg.sv"
`include "pa_pkg.sv"

module mem_arbitrer_tb
    import pa_pkg::*;
    import riscv_pkg::*;
();

    parameter integer CLK_PERIOD = 20;

    reg                                clk;
    reg                                rst;

    if_req_t                           if_req_i;
    if_resp_t                          if_resp_o;
    mm_read_req_t                      mm_read_req_i;
    mm_read_resp_t                     mm_read_resp_o;
    mm_write_req_t                     mm_write_req_i;
    mm_write_resp_t                    mm_write_resp_o;

    logic                              read_en_o;
    logic           [PHY_ADDR_LEN-1:0] read_addr_o;
    logic                              read_valid_i;
    logic           [        XLEN-1:0] read_data_i;
    logic                              write_en_o;
    logic           [PHY_ADDR_LEN-1:0] write_addr_o;
    logic           [        XLEN-1:0] write_data_o;
    logic                              write_valid_i;

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
        .read_en_o(read_en_o),
        .read_addr_o(read_addr_o),
        .read_valid_i(read_valid_i),
        .read_data_i(read_data_i),
        .write_en_o(write_en_o),
        .write_addr_o(write_addr_o),
        .write_data_o(write_data_o),
        .write_valid_i(write_valid_i)
    );

    initial begin
        $dumpfile("mem_arbitrer_tb.vcd");
        $dumpvars(0, mem_arbitrer_tb);
        clk = 1;
        rst = 1;
        #CLK_PERIOD rst = 0;

        $finish();
    end

endmodule
