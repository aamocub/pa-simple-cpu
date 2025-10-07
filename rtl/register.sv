module register #(
    parameter integer DATAWIDTH = 32
) (
    input  wire                 clk_i,
    input  wire                 rst_i,
    input  wire                 en_i,
    input  reg  [DATAWIDTH-1:0] d_i,
    output reg  [DATAWIDTH-1:0] q_o
);

    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            q_o <= '0;
        end else if (en_i) begin
            q_o <= d_i;
        end
    end

endmodule
