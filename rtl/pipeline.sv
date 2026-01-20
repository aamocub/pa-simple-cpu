module pipeline #(
    parameter integer unsigned CYCLES = 5,
    type data_t = logic
) (
    input  logic  clk_i,
    input  logic  rst_i,
    input  data_t d_i,
    output data_t q_o
);
    generate
        if (CYCLES == 0) begin : pipeline_blk1
            assign q_o = d_i;
        end else begin : pipeline_blk2
            data_t piperegs[CYCLES];
            assign q_o = piperegs[CYCLES-1];
            always_ff @(posedge clk_i, posedge rst_i) begin : PIPE_REG_0
                if (rst_i) piperegs[0] <= '0;
                else piperegs[0] <= d_i;
            end
            for (genvar i = 1; i < CYCLES; i = i + 1) begin : PIPE_REGS
                always_ff @(posedge clk_i, posedge rst_i) begin
                    if (rst_i) piperegs[i] <= '0;
                    else piperegs[i] <= piperegs[i-1];
                end
            end
        end
    endgenerate

endmodule
