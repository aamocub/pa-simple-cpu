module histfile
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter integer unsigned DEPTH = HISTFILE_DEPTH,
    localparam integer unsigned W = $clog2(DEPTH)
) (
    input  logic                  clk_i,
    input  logic                  rst_i,
    output logic                  empty_o,
    output logic                  full_o,
    /* --------------------------------------- Issue ports -------------------------------------- */
    input  logic       [   W-1:0] tail_i,    // Tail pointer
    input  logic                  issue_i,   // write enable (write entry_i into list)
    input  hf_entry_t             entry_i,   // Entry to be added
    /* --------------------------------------- Write ports -------------------------------------- */
    input  logic                  wren_i,    // Write enable
    input  logic       [   W-1:0] wrid_i,    // Entry id to be written to
    input  logic                  ready_i,   // Set entry's ready bit
    input  exception_t            evec_i,    // Set entry's exception vector
    /* --------------------------------------- Read ports --------------------------------------- */
    input  logic                  rden_i,    // Read enable
    input  logic       [   W-1:0] rdid_i,    // Entry id to be read from
    output logic       [XLEN-1:0] value_o,   // Value in entry
    output logic       [XLEN-1:0] rd_o,      // Rdest in entry
    /* -------------------------------------- Commit ports -------------------------------------- */
    input  logic       [   W-1:0] head_i,    // Head pointer
    input  logic                  commit_i,  // read enable (commit instruction at the head of the list)
    output hf_entry_t             entry_o    // Entry at head
);

    hf_entry_t list[DEPTH];
    logic [DEPTH-1:0] valids;

    assign entry_o = list[head_i];
    assign empty_o = tail_i == head_i && !full_o ? 1 : '0;
    assign full_o = &valids;
    assign value_o = rden_i ? list[rdid_i].value : '0;
    assign rd_o = rden_i ? list[rdid_i].rd : '0;

    generate
        for (genvar i = 0; i < DEPTH; i = i + 1) assign valids[i] = list[i].valid;
    endgenerate

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            foreach (list[i]) list[i] <= '0;
        end else begin
            if (issue_i && list[tail_i].valid == 0) begin
                list[tail_i] <= entry_i;
                list[tail_i].valid <= 1;
            end
            if (wren_i) begin
                list[wrid_i].ready <= ready_i;
                list[wrid_i].evec  <= evec_i;
            end
            if (commit_i) begin
                list[head_i].valid <= 0;
            end
        end
    end

endmodule
