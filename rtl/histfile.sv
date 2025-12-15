`include "hf_push_if.sv"
`include "hf_commit_if.sv"

/// TODO:
/// Recover logic in case of exception

module histfile
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter LEN = HF_LEN
) (
    input logic clk_i,
    input logic rst_i,

    hf_push_if   push_if,
    hf_commit_if commit_if,

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
            if (push_if.valid && !full_o) begin
                hf[tail] <= push_if.entry;
                push_if.position <= tail;
                tail <= ((tail + 1) % LEN);
            end
            // commit head
            if (hf[head].ready && hf[head].valid) begin
                hf[head].valid <= 0;
                commit_if.valid <= 1;
                commit_if.entry <= hf[head];
                head <= ((head + 1) % LEN);
            end
        end
    end

endmodule
