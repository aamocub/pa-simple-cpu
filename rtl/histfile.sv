`include "histfile_if.sv"

module histfile
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter LEN = HF_LEN
) (
    input logic clk_i,
    input logic rst_i,

    histfile_if id_if,

    output logic full_o,
    output logic empty_o
);

    logic [$clog2(LEN)-1:0] head;
    logic [$clog2(LEN)-1:0] tail;

    hf_entry_t hf[LEN];

    always_comb begin
        full_o  = head == ((tail + 1) % LEN);
        empty_o = head == tail;
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            head <= 0;
            tail <= 0;
            foreach (hf[i]) hf[i] <= 0;
        end else begin
            // push new entry to list
            if (id_if.valid && !full_o) begin
                hf[tail] <= id_if.entry;
                id_if.position <= tail;
                tail <= ((tail + 1) % LEN);
            end
        end
    end

endmodule
