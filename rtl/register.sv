module register #(
    parameter integer DATAWIDTH = 32
) (
    input  logic                 clk_i,
    input  logic                 rst_i,
    input  logic                 en_i,
    input  logic                 flush_i,
    input  logic [DATAWIDTH-1:0] d_i,
    output logic [DATAWIDTH-1:0] q_o
);

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            q_o <= '0;
        end else if (flush_i) begin
            q_o <= '0;
        end else if (en_i) begin
            q_o <= d_i;
        end
    end

endmodule
