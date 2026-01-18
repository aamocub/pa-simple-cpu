module top_tb ();
    import riscv_pkg::*;
    import pa_pkg::*;
    function automatic void load_file(string filename);
        string line;
        int fd = $fopen(filename, "r");
        int next_word = 0;
        while (!$feof(
            fd
        )) begin
            int err = $fgets(line, fd);
            top.memory.mem[PC_RESET_ADDR+4*next_word+:4] = line.atohex();
            next_word = next_word + 1;
        end
        $fclose(fd);
    endfunction

    logic clk, rst;
    localparam CLK_PERIOD = 20;

    always #(CLK_PERIOD / 2) clk = ~clk;

    top #(
        .MEMLEN(4096)
    ) top (
        .clk_i(clk),
        .rst_i(rst)
    );

    initial #(CLK_PERIOD * 1000) $finish();

    initial begin
        string filename;

        $dumpfile("top_tb.fst");
        $dumpvars(0, top_tb);

        if (!$value$plusargs("load=%s", filename)) begin
            $error("missing +load=<filename> arg");
        end

        clk = 1;
        rst = 1;
        $display("%t tb: loading test binary (%s)", $time, filename);
        load_file(filename);
        #(CLK_PERIOD) rst = 0;
        $display("%t tb: reset done", $time);
        wait (top.core.cu.is_exception);
        // #(CLK_PERIOD * 200);
        $display("%t tb: system halted", $time);

        if (top.core.id_stage.regfile.bank[17] == 93) begin
            static int testnum = top.core.id_stage.regfile.bank[3] >> 1;
            static int err = top.core.id_stage.regfile.bank[10];
            if (err == 0) begin
                $display("%t tb: RESULT -> SUCCESS", $time);
            end else begin
                $display("%t tb: RESULT -> FAILURE (test_%0d, err=%0d)", $time, testnum, err);
            end
        end
        $finish();

    end
endmodule
