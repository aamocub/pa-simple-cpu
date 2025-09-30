module cmp #(
    parameter integer DATAWIDTH = 32
) (
    input  wire [DATAWIDTH-1:0] a_i,
    input  wire [DATAWIDTH-1:0] b_i,
    output wire eq_o,
    output wire gt_o,
    output wire lt_o
);

    assign eq_o = a_i == b_i;
    assign gt_o = a_i > b_i;
    assign lt_o = a_i < b_i;

endmodule