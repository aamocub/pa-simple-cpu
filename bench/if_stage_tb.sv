

module if_stage_tb
    import riscv_pkg::*;
    import pa_pkg::*;
();
    localparam CLK_PERIOD = 20;

    logic clk;
    logic rst;
    pa_pkg::cu_if_t ctrl = '{default: 0};
    pa_pkg::if_stage_t ifout;
    cache_intf icache ();

    if_stage if_stage (
        .clk_i   (clk),
        .rst_i   (rst),
        .cu_i    (ctrl),
        .if_o    (ifout),
        .cache_io(icache.CL)
    );


    always #(CLK_PERIOD / 2) clk <= ~clk;
    initial begin

        $dumpfile("if_stage_tb.fst");
        $dumpvars(0, if_stage_tb);
        clk = 1;
        rst = 1;

        #CLK_PERIOD rst = 0;


        #(CLK_PERIOD * 5);

        icache.resp.valid = 1;
        icache.resp.data  = NOP_INSTR;

        #(CLK_PERIOD * 10);

        $finish();
    end

endmodule
