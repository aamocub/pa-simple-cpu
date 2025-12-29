// - Directly mapped
// - Write-back
// - Write-allocate

module cache
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter integer unsigned LINE_LEN = CACHE_LINE_LEN,
    localparam integer unsigned NUM_SETS = 4,
    localparam integer unsigned M = $clog2(LINE_LEN / 8),
    localparam integer unsigned N = $clog2(NUM_SETS) + M
) (
    input logic clk_i,
    input logic rst_i,
    memory_intf.SV stage_io,
    memory_intf.CL mem_io
);

    typedef enum {
        IDLE,
        MISS,
        WRITEBACK,
        WAIT,
        WRITE
    } state_t;
    typedef struct packed {
        logic valid;
        logic dirty;
        logic [PHY_ADDR_LEN-N-1:0] tag;
        logic [LINE_LEN-1:0] data;
    } line_t;
    typedef struct packed {
        logic valid;
        logic write_en;
        mem_width_t kind;
        logic [PHY_ADDR_LEN-1:0] addr;
        logic [XLEN-1:0] data;
    } pending_req_t;

    state_t state;
    line_t line[NUM_SETS];
    logic is_req_in_cache;
    pending_req_t pending_read, pending_write;

    wire [PHY_ADDR_LEN-N-1:0] tag;
    wire [N-M-1:0] idx;
    wire [M-1:0] offset;
    assign tag = stage_io.req_addr[PHY_ADDR_LEN-1:N];
    assign idx = stage_io.req_addr[N-1:M];
    assign offset = stage_io.req_addr[M-1:0];

    assign is_req_in_cache = stage_io.req_valid && line[idx].valid && tag == line[idx].tag;

    always_ff @(posedge clk_i, posedge rst_i) begin : transitions
        if (rst_i) begin
            state <= IDLE;
        end else begin
            unique case (state)
                IDLE: begin
                    state <= (stage_io.req_valid && !is_req_in_cache) ? MISS : state;
                end
                MISS: begin
                    if (line[idx].valid && line[idx].dirty) begin
                        state <= WRITEBACK;
                    end else begin
                        state <= WAIT;
                    end
                end
                WRITEBACK: begin
                    state <= WAIT;
                end
                WAIT: begin
                    if (mem_io.resp_valid) begin
                        if (pending_write.valid) state <= WRITE;
                        else state <= IDLE;
                    end else begin
                        state <= state;
                    end
                end
                WRITE: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            foreach (line[i]) line[i] <= '0;
        end else begin
            stage_io.resp_valid <= 0;
            mem_io.req_valid <= '0;
            mem_io.req_addr <= '0;
            mem_io.req_data <= '0;
            mem_io.req_write_en <= '0;
            unique case (state)
                IDLE: begin
                    pending_read  <= '0;
                    pending_write <= '0;
                    if (is_req_in_cache) begin
                        stage_io.resp_valid <= 1;
                        unique case (stage_io.req_write_en)
                            0: begin  // READ
                                unique case (stage_io.req_type)
                                    WORD: stage_io.resp_data <= line[idx].data[offset*8+:32];
                                    HALF, UHALF:
                                    stage_io.resp_data <= {16'b0, line[idx].data[offset*8+:16]};
                                    BYTE, UBYTE:
                                    stage_io.resp_data <= {24'b0, line[idx].data[offset*8+:8]};
                                endcase
                            end
                            1: begin  // WRITE
                                line[idx].dirty <= 1;
                                unique case (stage_io.req_type)
                                    WORD: line[idx].data[offset*8+:32] <= stage_io.req_data;
                                    HALF, UHALF:
                                    line[idx].data[offset*8+:16] <= stage_io.req_data[15:0];
                                    BYTE, UBYTE:
                                    line[idx].data[offset*8+:8] <= stage_io.req_data[7:0];
                                endcase
                            end
                        endcase
                    end else begin
                        if (stage_io.req_write_en) begin
                            pending_write.valid <= stage_io.req_valid;
                            pending_write.addr <= stage_io.req_addr;
                            pending_write.data <= stage_io.req_data;
                            pending_write.write_en <= stage_io.req_write_en;
                            pending_write.kind <= stage_io.req_type;
                        end else if (line[idx].valid && line[idx].dirty) begin
                            pending_read.valid <= !stage_io.req_write_en;
                            pending_read.addr  <= stage_io.req_addr;
                        end
                    end
                end
                MISS: begin
                    mem_io.req_valid <= 1;
                    if (line[idx].valid && line[idx].dirty) begin : WRITE_BACK
                        pending_read.valid  <= !stage_io.req_write_en;
                        pending_read.addr   <= stage_io.req_addr;
                        mem_io.req_addr     <= {line[idx].tag, idx, {M{1'b0}}};
                        mem_io.req_write_en <= 1;
                        mem_io.req_data     <= line[idx].data;
                    end else begin
                        mem_io.req_addr <= {tag, idx, {M{1'b0}}};
                        line[idx].tag   <= stage_io.req_addr[PHY_ADDR_LEN-1:N];
                    end
                end
                WRITEBACK: begin
                    mem_io.req_valid <= pending_read.valid;
                    mem_io.req_addr <= pending_read.addr;
                    mem_io.req_write_en <= 0;
                    pending_read <= '0;
                end
                WAIT: begin
                    if (mem_io.resp_valid) begin
                        line[idx].valid <= 1;
                        line[idx].dirty <= 0;
                        line[idx].data <= mem_io.resp_data;
                        stage_io.resp_data <= mem_io.resp_data[offset*8+:XLEN];
                        if (!pending_write.valid) begin
                            stage_io.resp_valid <= 1;
                        end
                    end
                end
                WRITE: begin
                    stage_io.resp_valid <= 1;
                    pending_write <= '0;
                    line[pending_write.addr[N-1:M]].dirty <= 1;
                    unique case (pending_write.kind)
                        WORD:
                        line[pending_write.addr[N-1:M]].data[pending_write.addr[M-1:0]*8+:32] <= pending_write.data;
                        HALF, UHALF:
                        line[pending_write.addr[N-1:M]].data[pending_write.addr[M-1:0]*8+:16] <= pending_write.data[15:0];
                        BYTE, UBYTE:
                        line[pending_write.addr[N-1:M]].data[pending_write.addr[M-1:0]*8+:8] <= pending_write.data[7:0];
                    endcase
                end
            endcase
        end
    end

endmodule
