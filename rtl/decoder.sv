module decoder #(
    parameter integer N = 16
) (
    input  logic [N-1:0]    in_i,
    input  logic            enable_i,
    output logic [2**N-1:0] out_o
);

    always_comb begin
        out_o = 0;
        out_o[in_i] = enable_i;
    end

endmodule