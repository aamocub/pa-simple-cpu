module register #(
    type reg_t = logic
) (
    input  logic clk_i,
    input  logic rst_i,
    input  logic en_i,
    input  logic flush_i,
    input  reg_t default_i,
    input  reg_t d_i,
    output reg_t q_o
);

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i || flush_i) begin
            q_o <= default_i;
        end else if (en_i) begin
            q_o <= d_i;
        end
    end

endmodule
