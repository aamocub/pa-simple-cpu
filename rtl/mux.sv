module mux #(
    parameter integer N = 16,
    parameter integer DATAWIDTH = 32
) (
    input  wire [DATAWIDTH-1:0] in_i[N],
    input  wire [$clog2(N)-1:0] control_i,
    output wire [DATAWIDTH-1:0] out_o
);

    assign out_o = in_i[control_i];

endmodule