module store_buffer
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter integer unsigned DEPTH = SB_DEPTH,
    localparam integer unsigned W = $clog2(DEPTH)
) (
    input logic clk_i,
    input logic rst_i,
    input sb_entry_t entry_i,
    input logic issue_i,
    input logic commit_i,
    output sb_entry_t entry_o,
    output logic full_o,
    output logic emtpy_o,
    output sb_entry_t [DEPTH-1:0] entries_o,
    output logic [W-1:0] tail_o,
    output logic [W-1:0] head_o
);

    sb_entry_t [DEPTH-1:0] entries;
    logic [W-1:0] head, tail;
    logic [DEPTH-1:0] valids;

    assign entries_o = entries;
    assign tail_o = tail;
    assign head_o = head;

    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin
            assign valids[i] = entries[i].valid;
        end
    endgenerate

    assign full_o  = &valids && tail == head;
    assign empty_o = |valids == 0 && tail == head;
    assign entry_o = entries[head];

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            entries <= '0;
            head <= 0;
            tail <= 0;
        end else begin
            if (issue_i && !full_o) begin
                entries[tail] <= entry_i;
                tail <= (tail + 1) % DEPTH;
            end
            if (commit_i) begin
                entries[head] <= '0;
                head <= (head + 1) % DEPTH;
            end
        end
    end

endmodule
