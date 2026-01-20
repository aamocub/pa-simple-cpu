module mm_stage
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter  integer unsigned LINE_LEN   = CACHE_LINE_LEN,
    parameter  integer unsigned ADDR_WIDTH = PHY_ADDR_LEN,
    localparam integer unsigned NUM_SETS   = 4,
    localparam integer unsigned M          = $clog2(LINE_LEN / 8),
    localparam integer unsigned N          = $clog2(NUM_SETS) + M
) (
    input  logic          clk_i,
    input  logic          rst_i,
    input  ex_stage_t     ex_i,
    input  cu_mm_t        cu_i,
    output mm_stage_t     mm_o,
           memory_intf.CL mem_io
);
    typedef struct packed {
        logic                    valid;
        logic                    dirty;
        logic [ADDR_WIDTH-N-1:0] tag;
        logic [LINE_LEN-1:0]     data;
    } line_t;
    typedef enum {
        E_IDLE_OR_HIT,
        E_MISS
    } state_t;

    state_t state_q, state_d;
    line_t [  NUM_SETS-1:0] lines;
    wire   [ADDR_WIDTH-1:0] addr = ex_i.alu_result;

    function automatic tag(logic [ADDR_WIDTH-1:0] addr);
        return addr[ADDR_WIDTH-1:N];
    endfunction
    function automatic idx(logic [ADDR_WIDTH-1:0] addr);
        return addr[N-1:M];
    endfunction
    function automatic offset(logic [ADDR_WIDTH-1:0] addr);
        return addr[M-1:0];
    endfunction
    function automatic hit(logic [ADDR_WIDTH-1:0] addr);
        return lines[idx(addr)].tag == tag(addr) && lines[idx(addr)].valid;
    endfunction
    function automatic dirty(logic [ADDR_WIDTH-1:0] addr);
        return lines[idx(addr)].dirty;
    endfunction

    sb_entry_t                        sb_entry_in;
    logic                             sb_issue;
    logic                             sb_commit;
    sb_entry_t                        sb_entry_out;
    logic                             sb_full;
    logic                             sb_empty;
    logic      [$clog2(SB_DEPTH)-1:0] sb_head;
    logic      [$clog2(SB_DEPTH)-1:0] sb_tail;
    sb_entry_t [        SB_DEPTH-1:0] sb_entries;
    store_buffer store_buffer (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .entry_i (sb_entry_in),
        .issue_i (sb_issue),
        .commit_i(sb_commit),
        .entry_o (sb_entry_out),
        .full_o  (sb_full),
        .emtpy_o (sb_empty),
        .entries_o (sb_entries),
        .tail_o (sb_tail),
        .head_o (sb_head)
    );

    always_comb begin : passthrough_signals
        mm_o.rd       = ex_i.rd;
        mm_o.rs1      = ex_i.rs1;
        mm_o.rs2      = ex_i.rs2;
        mm_o.pc       = ex_i.pc;
        mm_o.hf_id    = ex_i.hf_id;
        mm_o.is_wb    = ex_i.is_wb;
        mm_o.data_rs2 = ex_i.data_rs2;
        mm_o.valid    = ex_i.valid;
        mm_o.evec     = ex_i.evec;
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            lines   <= '0;
            state_q <= E_IDLE_OR_HIT;
        end else begin
            state_q <= state_d;
        end
    end
    always_comb begin
        state_d = state_q;
        unique case (state_q)
            E_IDLE_OR_HIT: begin
                if (ex_i.is_ld && !hit(addr)) begin
                    state_d = E_MISS;
                end
            end
            E_MISS: begin
            end
        endcase
    end
    logic sb_hit;
    logic cc_hit;
    logic sb_ld_hazard;
    always_comb begin
        sb_commit           = 0;
        sb_issue            = 0;
        sb_entry_in         = '0;
        mem_io.req_write_en = '0;
        mem_io.req_valid    = '0;
        mem_io.req_addr     = '0;
        mem_io.req_type     = ex_i.mem_width;
        mem_io.req_data     = '0;
        mm_o.data           = ex_i.alu_result;
        mm_o.do_stall       = 0;
        unique case (state_q)
            E_IDLE_OR_HIT: begin
                // LOAD instruction
                if (ex_i.is_ld) begin
                    // Check hit on SB
                    if (!sb_empty) begin
                        if (sb_entries[(sb_tail-1) % SB_DEPTH].valid && sb_entries[(sb_tail-1) % SB_DEPTH].addr == addr) begin
                            sb_hit = 1;
                            mm_o.data = sb_entries[(sb_tail-1)%SB_DEPTH].data;
                        end else if (sb_entries[(sb_tail-2) % SB_DEPTH].valid && sb_entries[(sb_tail-2) % SB_DEPTH].addr == addr) begin
                            sb_hit = 1;
                            mm_o.data = sb_entries[(sb_tail-2)%SB_DEPTH].data;
                        end else if (sb_entries[(sb_tail-3) % SB_DEPTH].valid && sb_entries[(sb_tail-3) % SB_DEPTH].addr == addr) begin
                            sb_hit = 1;
                            mm_o.data = sb_entries[(sb_tail-3)%SB_DEPTH].data;
                        end else if (sb_entries[(sb_tail-4) % SB_DEPTH].valid && sb_entries[(sb_tail-4) % SB_DEPTH].addr == addr) begin
                            sb_hit = 1;
                            mm_o.data = sb_entries[(sb_tail-4)%SB_DEPTH].data;
                        end
                    end else sb_hit = 0;
                    // Check SB-LD hazard
                    // verilog_format:off
                    if (sb_entries[(sb_tail-1)%SB_DEPTH].valid &&
                        idx( sb_entries[(sb_tail-1)%SB_DEPTH].addr) == idx( addr) ||
                        sb_entries[(sb_tail-2)%SB_DEPTH].valid &&
                        idx( sb_entries[(sb_tail-2)%SB_DEPTH].addr) == idx( addr) ||
                        sb_entries[(sb_tail-3)%SB_DEPTH].valid &&
                        idx( sb_entries[(sb_tail-3)%SB_DEPTH].addr) == idx( addr) ||
                        sb_entries[(sb_tail-4)%SB_DEPTH].valid &&
                        idx( sb_entries[(sb_tail-4)%SB_DEPTH].addr) == idx( addr)) begin
                        sb_ld_hazard = 1;
                    end
                    // verilog_format:on
                    // Check hit on CACHE
                    if (!sb_hit && !sb_ld_hazard) begin
                        if (hit(addr)) begin
                            cc_hit = 1;
                            unique case (ex_i.mem_width)
                                BYTE:  mm_o.data = {{24{lines[idx(addr)].data[7]}}, lines[idx(addr)].data[7:0]};
                                UBYTE: mm_o.data = {24'b0, lines[idx(addr)].data[7:0]};
                                HALF:  mm_o.data = {{16{lines[idx(addr)].data[15]}}, lines[idx(addr)].data[15:0]};
                                UHALF: mm_o.data = {16'b0, lines[idx(addr)].data[15:0]};
                                WORD:  mm_o.data = {lines[idx(addr)].data};
                            endcase
                        end else begin
                            // TODO: LD no hit
                        end
                    end
                end else if (ex_i.is_st) begin
                    // STORE instruction
                    if (!sb_full) begin
                        if (hit(addr)) begin
                            sb_entry_in.valid = 1;
                            sb_entry_in.addr  = addr;
                            sb_entry_in.data  = ex_i.data_rs2;
                            sb_entry_in.hf_id = ex_i.hf_id;
                            sb_issue          = 1;
                        end else begin
                            // TODO: STORE no hit
                        end
                    end
                end else begin
                    // NO STORE OR LOAD instruction (commit entry in buffer)
                    if (cu_i.hf_head_id == sb_entries[sb_head].hf_id &&
                        sb_entries[sb_head].valid &&
                        cu_i.hf_commit) begin
                        // Write SB entry to CACHE
                        sb_commit = 1;
                        lines[idx(sb_entry_out.addr)].dirty <= 1;
                        unique case (sb_entry_out.kind)
                            BYTE, UBYTE: begin
                                lines[idx(sb_entry_out.addr)].data[offset(sb_entry_out.addr)*8+:8] <=
                                    sb_entry_out.data[7:0];
                            end
                            HALF, UHALF: begin
                                lines[idx(sb_entry_out.addr)].data[offset(sb_entry_out.addr)*8+:16] <=
                                    sb_entry_out.data[15:0];
                            end
                            WORD: begin
                                lines[idx(sb_entry_out.addr)].data[offset(sb_entry_out.addr)*8+:32] <=
                                    sb_entry_out.data[31:0];
                            end
                        endcase
                    end
                end
            end
            E_MISS: begin
            end
        endcase
    end

endmodule
