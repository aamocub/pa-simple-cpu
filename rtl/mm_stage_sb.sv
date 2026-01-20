module mm_stage_sb
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
        E_MISS,
        E_EVICT,
        E_EVICT_ACK,
        E_WRITE,
        E_DRAIN
    } state_t;

    state_t state_q, state_d;
    line_t      [  NUM_SETS-1:0] lines;
    wire        [ADDR_WIDTH-1:0] addr = ex_i.alu_result;
    logic                        pend_req_write_en;
    logic                        pend_req_valid;
    logic       [ADDR_WIDTH-1:0] pend_req_addr;
    mem_width_t                  pend_req_type;
    logic       [      XLEN-1:0] pend_req_data;
    logic       [      XLEN-1:0] data_from_line;

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
        mm_o.sb_full  = sb_full;
        mm_o.sb_empty = sb_empty;
        mm_o.is_ld    = ex_i.is_ld;
        mm_o.is_st    = ex_i.is_st;
    end

    logic                        sb_hit;
    logic                        cc_hit;
    logic                        cc_dirty_miss;
    logic                        sb_ld_hazard;
    logic [$clog2(SB_DEPTH)-1:0] sb_drain_ptr;
    always_ff @(posedge clk_i, posedge rst_i) begin : fsm_state_register
        if (rst_i) begin
            state_q <= E_IDLE_OR_HIT;
        end else begin
            state_q <= state_d;
        end
    end
    always_ff @(posedge clk_i, posedge rst_i) begin : fsm_cache_management
        if (rst_i) begin
            lines <= '0;
        end else begin
            unique case (state_q)
                E_IDLE_OR_HIT: begin
                    pend_req_write_en <= ex_i.is_st ? 1 : 0;
                    pend_req_valid <= ex_i.is_st || ex_i.is_ld ? 1 : 0;
                    pend_req_addr <= ex_i.alu_result;
                    pend_req_type <= ex_i.mem_width;
                    pend_req_data <= ex_i.data_rs2;
                    // Write SB entry to CACHE
                    if (!ex_i.is_ld && !ex_i.is_st &&
                         cu_i.hf_head_id == sb_entries[sb_head].hf_id &&
                         sb_entries[sb_head].valid &&
                         cu_i.hf_commit) begin
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
                E_MISS: begin
                    if (mem_io.resp_valid) begin
                        lines[idx(pend_req_addr)].valid <= 1;
                        lines[idx(pend_req_addr)].dirty <= 0;
                        lines[idx(pend_req_addr)].tag   <= tag(pend_req_addr);
                        lines[idx(pend_req_addr)].data  <= mem_io.resp_data;
                    end
                end
                E_EVICT: begin
                    lines[idx(pend_req_addr)] <= '0;
                end
                E_EVICT_ACK: begin
                end
                E_WRITE: begin
                    lines[idx(pend_req_addr)].valid <= 1;
                    lines[idx(pend_req_addr)].dirty <= 1;
                    lines[idx(pend_req_addr)].tag   <= tag(pend_req_addr);
                    unique case (pend_req_type)
                        BYTE, UBYTE: begin
                            lines[idx(pend_req_addr)].data[offset(pend_req_addr)*8+:8] <= pend_req_data[7:0];
                        end
                        HALF, UHALF: begin
                            lines[idx(pend_req_addr)].data[offset(pend_req_addr)*8+:16] <= pend_req_data[15:0];
                        end
                        WORD: begin
                            lines[idx(pend_req_addr)].data[offset(pend_req_addr)*8+:32] <= pend_req_data[31:0];
                        end
                    endcase
                end
                E_DRAIN: begin
                    if ( cu_i.hf_head_id == sb_entries[sb_head].hf_id &&
                         sb_entries[sb_head].valid &&
                         cu_i.hf_commit) begin
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
            endcase
        end
    end
    always_comb begin : fsm_transitions
        state_d = state_q;
        unique case (state_q)
            E_IDLE_OR_HIT: begin
                if (ex_i.is_ld) begin
                    if (!cc_hit && !sb_hit && !sb_ld_hazard && !cc_dirty_miss) begin
                        state_d = E_MISS;
                    end else if (!cc_hit && !sb_hit && !sb_ld_hazard && cc_dirty_miss) begin
                        state_d = E_EVICT;
                    end
                end
                if (ex_i.is_st) begin
                    if (!cc_hit && !cc_dirty_miss) begin
                        state_d = E_MISS;
                    end else if (!cc_hit && cc_dirty_miss) begin
                        state_d = E_EVICT;
                    end
                end
            end
            E_MISS: begin
                state_d = mem_io.resp_valid ? (pend_req_write_en ? E_WRITE : E_IDLE_OR_HIT) : E_MISS;
            end
            E_EVICT: begin
                state_d = E_EVICT_ACK;
            end
            E_EVICT_ACK: begin
                state_d = mem_io.resp_valid ? E_MISS : E_EVICT_ACK;
            end
            E_WRITE: begin
                state_d = E_IDLE_OR_HIT;
            end
            E_DRAIN: begin
                state_d = sb_tail == sb_head ? E_IDLE_OR_HIT : E_DRAIN;
            end
        endcase
    end
    always_comb begin : fsm_logic
        data_from_line      = '0;
        sb_commit           = 0;
        sb_issue            = 0;
        sb_entry_in         = '0;
        sb_hit              = 0;
        sb_ld_hazard        = 0;
        cc_hit              = 0;
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
                    end
                    // Check SB-LD hazard
                    // verilog_format:off
                    if (sb_entries[(sb_tail-1)%SB_DEPTH].valid &&
                        idx( sb_entries[(sb_tail-1)%SB_DEPTH].addr ) == idx( addr ) ||
                        sb_entries[(sb_tail-2)%SB_DEPTH].valid &&
                        idx( sb_entries[(sb_tail-2)%SB_DEPTH].addr ) == idx( addr ) ||
                        sb_entries[(sb_tail-3)%SB_DEPTH].valid &&
                        idx( sb_entries[(sb_tail-3)%SB_DEPTH].addr ) == idx( addr ) ||
                        sb_entries[(sb_tail-4)%SB_DEPTH].valid &&
                        idx( sb_entries[(sb_tail-4)%SB_DEPTH].addr ) == idx( addr )) begin
                        sb_ld_hazard = 1;
                        mm_o.do_stall = 1;
                    end
                    // verilog_format:on
                    // Check hit on CACHE
                    if (!sb_hit && !sb_ld_hazard) begin
                        if (hit(addr)) begin
                            cc_hit = 1;
                            unique case (ex_i.mem_width)
                                BYTE: begin
                                    data_from_line = mem_io.resp_data[offset(addr)*8+:8];
                                    mm_o.data = {{24{data_from_line[7]}}, data_from_line[7:0]};
                                end
                                UBYTE: begin
                                    data_from_line = mem_io.resp_data[offset(addr)*8+:8];
                                    mm_o.data = {24'b0, data_from_line[7:0]};
                                end
                                HALF: begin
                                    data_from_line = mem_io.resp_data[offset(addr)*8+:16];
                                    mm_o.data = {{16{data_from_line[15]}}, data_from_line[15:0]};
                                end
                                UHALF: begin
                                    data_from_line = mem_io.resp_data[offset(addr)*8+:16];
                                    mm_o.data = {16'b0, data_from_line[15:0]};
                                end
                                WORD: begin
                                    data_from_line = mem_io.resp_data[offset(addr)*8+:16];
                                    data_from_line = data_from_line;
                                end
                            endcase
                        end else begin
                            cc_dirty_miss       = lines[idx(addr)].dirty;
                            mm_o.do_stall       = 1;
                            mem_io.req_write_en = 0;
                            mem_io.req_valid    = 1;
                            mem_io.req_addr     = {tag(addr), idx(addr), {M{1'b0}}};
                            mem_io.req_type     = ex_i.mem_width;
                            mem_io.req_data     = '0;
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
                            cc_dirty_miss       = lines[idx(addr)].dirty;
                            mm_o.do_stall       = 1;
                            mem_io.req_write_en = 0;
                            mem_io.req_valid    = 1;
                            mem_io.req_addr     = {tag(addr), idx(addr), {M{1'b0}}};
                            mem_io.req_type     = ex_i.mem_width;
                            mem_io.req_data     = '0;
                            // TODO: STORE no hit
                        end
                    end else begin
                    end
                end else begin
                    // NO STORE OR LOAD instruction (commit entry in buffer)
                    if (cu_i.hf_head_id == sb_entries[sb_head].hf_id &&
                        sb_entries[sb_head].valid &&
                        cu_i.hf_commit) begin
                        // Write SB entry to CACHE
                        sb_commit = 1;
                    end
                end
            end
            E_MISS: begin
                mm_o.do_stall = 1;
                if (mem_io.resp_valid) begin
                    if (!pend_req_write_en) begin
                        unique case (pend_req_type)
                            BYTE: begin
                                data_from_line = mem_io.resp_data[offset(pend_req_addr)*8+:8];
                                mm_o.data = {{24{data_from_line[7]}}, data_from_line[7:0]};
                            end
                            UBYTE: begin
                                data_from_line = mem_io.resp_data[offset(pend_req_addr)*8+:8];
                                mm_o.data = {24'b0, data_from_line[7:0]};
                            end
                            HALF: begin
                                data_from_line = mem_io.resp_data[offset(pend_req_addr)*8+:16];
                                mm_o.data = {{16{data_from_line[15]}}, data_from_line[15:0]};
                            end
                            UHALF: begin
                                data_from_line = mem_io.resp_data[offset(pend_req_addr)*8+:16];
                                mm_o.data = {16'b0, data_from_line[15:0]};
                            end
                            WORD: begin
                                data_from_line = mem_io.resp_data[offset(pend_req_addr)*8+:16];
                                data_from_line = data_from_line;
                            end
                        endcase
                    end
                end
            end
            E_EVICT: begin
                mm_o.do_stall       = 1;
                // Send cache line to be written back to memory
                mem_io.req_write_en = 1;
                mem_io.req_valid    = 1;
                mem_io.req_addr     = {lines[idx(pend_req_addr)].tag, idx(pend_req_addr), {M{1'b0}}};
                mem_io.req_type     = pend_req_type;
                mem_io.req_data     = lines[idx(pend_req_addr)].data;
            end
            E_EVICT_ACK: begin
                mm_o.do_stall = 1;
                // Once cache line is written to memory, request the corresponding line
                if (mem_io.resp_valid) begin
                    mem_io.req_write_en = 0;
                    mem_io.req_valid    = 1;
                    mem_io.req_addr     = {tag(pend_req_addr), idx(pend_req_addr), {M{1'b0}}};
                    mem_io.req_type     = pend_req_type;
                    mem_io.req_data     = '0;
                end
            end
            E_WRITE: begin
                mm_o.do_stall = 1;
            end
            E_DRAIN: begin
                mm_o.do_stall = 1;
                if (cu_i.hf_head_id == sb_entries[sb_head].hf_id && sb_entries[sb_head].valid && cu_i.hf_commit) begin
                    // Write SB entry to CACHE
                    sb_commit = 1;
                end
            end
        endcase
    end

endmodule
