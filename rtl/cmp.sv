module cmp #(
    parameter integer DATAWIDTH = 32
) (
    input wire [DATAWIDTH-1:0] a_i,
    input wire [DATAWIDTH-1:0] b_i,
    input wire [1:0] op_i,
    output wire out_o
);

    assign out_o = (op_i == 2'b00) ? 0 :
                   (op_i == 2'b01) ? a_i == b_i :
                   (op_i == 2'b10) ? a_i >  b_i :
                   (op_i == 2'b11) ? a_i >= b_i :
                    'x;

endmodule
