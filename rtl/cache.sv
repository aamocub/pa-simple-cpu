module cache
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter integer unsigned LINE_LEN   = CACHE_LINE_LEN,
    parameter integer unsigned ADDR_WIDTH = PHY_ADDR_LEN
) (
    input logic clk_i,
    input logic rst_i,
    memory_intf.SV core_io,
    memory_intf.CL mem_io
);

    localparam integer unsigned NUM_SETS = 4;
    localparam integer unsigned M = $clog2(LINE_LEN / 8);

    typedef struct packed {
        logic                  valid, write;
        logic [ADDR_WIDTH-1:0] addr;
        logic [XLEN-1:0]       data;
        mem_width_t            kind;
    } req_t;

    // verilog_format: off
    enum { IDLE, MISS, SEND_SAVE, WRITEBACK, WRITE } state;
    // verilog_format: on

    req_t pending_req, next_req;
    wire [M-1:0] offset = pending_req.addr[M-1:0];

    logic [ADDR_WIDTH-1:0] addr_to_cache;
    logic write_to_cache;
    logic write_line_to_cache;
    logic [LINE_LEN-1:0] write_data_to_cache;
    mem_width_t width;
    logic [XLEN-1:0] data_from_cache;
    logic [LINE_LEN-1:0] line_from_cache;
    logic is_hit, is_dirty;

    cache_data #(
        .LINE_LEN  (LINE_LEN),
        .NUM_SETS  (NUM_SETS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) cache_data (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .addr_i      (addr_to_cache),
        .write_i     (write_to_cache),
        .write_line_i(write_line_to_cache),
        .write_data_i(write_data_to_cache),
        .kind_i      (width),
        .hit_o       (is_hit),
        .dirty_o     (is_dirty),
        .data_o      (data_from_cache),
        .line_data_o (line_from_cache)
    );

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            pending_req <= '0;
        end else begin
            unique case (state)
                IDLE: begin
                    if (core_io.req_valid) begin
                        pending_req.valid <= 1;
                        pending_req.write <= core_io.req_write_en;
                        pending_req.addr  <= core_io.req_addr;
                        pending_req.data  <= core_io.req_data;
                        pending_req.kind  <= core_io.req_type;
                        if (!is_hit) begin
                            state <= is_dirty ? WRITEBACK : MISS;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end
                MISS: begin
                    if (mem_io.resp_valid) begin
                        state <= pending_req.write ? WRITE : core_io.req_valid ? SEND_SAVE : IDLE;
                        if (pending_req.write) begin
                            state <= WRITE;
                        end else if (core_io.req_valid) begin
                            next_req.valid <= 1;
                            next_req.write <= core_io.req_write_en;
                            next_req.addr <= core_io.req_addr;
                            next_req.data <= core_io.req_data;
                            next_req.kind <= core_io.req_type;
                            state <= SEND_SAVE;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end
                SEND_SAVE: begin
                    if (!is_hit) begin
                        pending_req.valid <= 1;
                        pending_req.write <= core_io.req_write_en;
                        pending_req.addr <= core_io.req_addr;
                        pending_req.data <= core_io.req_data;
                        pending_req.kind <= core_io.req_type;
                        state <= is_dirty ? WRITEBACK : MISS;
                    end else if (core_io.req_valid) begin
                        next_req.valid <= 1;
                        next_req.write <= core_io.req_write_en;
                        next_req.addr <= core_io.req_addr;
                        next_req.data <= core_io.req_data;
                        next_req.kind <= core_io.req_type;
                        state <= SEND_SAVE;
                    end else begin
                        state <= IDLE;
                    end
                end
                WRITEBACK: begin
                    state <= MISS;
                end
                WRITE: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    always_comb begin
        core_io.resp_valid = 0;
        core_io.resp_data = '0;
        addr_to_cache = '0;
        write_to_cache = '0;
        write_data_to_cache = '0;
        write_line_to_cache = 0;
        mem_io.req_valid = '0;
        mem_io.req_addr = '0;
        mem_io.req_data = '0;
        mem_io.req_write_en = '0;
        mem_io.req_type = BYTE;
        width = core_io.req_type;
        unique case (state)
            IDLE: begin
                addr_to_cache = core_io.req_addr;
                if (core_io.req_valid) begin
                    if (is_hit) begin
                        core_io.resp_valid = 1;
                        core_io.resp_data  = data_from_cache;
                        if (core_io.req_write_en) begin
                            write_to_cache = 1;
                            write_data_to_cache = {96'b0, core_io.req_data};
                        end
                    end else begin
                        if (is_dirty) begin : WRITEBACK_LINE
                            mem_io.req_valid = 1;
                            mem_io.req_addr = {core_io.req_addr[ADDR_WIDTH-1:M], {M{1'b0}}};
                            mem_io.req_write_en = 1;
                            mem_io.req_data = line_from_cache;
                        end else begin : GET_LINE
                            mem_io.req_valid = 1;
                            mem_io.req_addr = {core_io.req_addr[ADDR_WIDTH-1:M], {M{1'b0}}};
                            mem_io.req_write_en = 0;
                        end
                    end
                end
            end
            MISS: begin
                addr_to_cache = pending_req.addr;
                if (mem_io.resp_valid) begin
                    write_data_to_cache = mem_io.resp_data;
                    write_line_to_cache = 1;
                    if (!pending_req.write) begin
                        core_io.resp_valid = 1;
                        unique case (pending_req.kind)
                            WORD: core_io.resp_data = mem_io.resp_data[offset*8+:32];
                            HALF, UHALF: core_io.resp_data = {16'b0, mem_io.resp_data[offset*8+:16]};
                            BYTE, UBYTE: core_io.resp_data = {24'b0, mem_io.resp_data[offset*8+:8]};
                        endcase
                    end
                end
            end
            SEND_SAVE: begin
                addr_to_cache = next_req.addr;
                if (is_hit) begin
                    core_io.resp_valid = 1;
                    core_io.resp_data  = data_from_cache;
                    if (next_req.write) begin
                        write_to_cache = 1;
                        write_data_to_cache = {96'b0, next_req.data};
                    end
                end else begin
                    if (is_dirty) begin
                        mem_io.req_valid = 1;
                        mem_io.req_addr = {next_req.addr[ADDR_WIDTH-1:M], {M{1'b0}}};
                        mem_io.req_write_en = 1;
                        mem_io.req_data = line_from_cache;
                    end else begin
                        mem_io.req_valid = 1;
                        mem_io.req_addr = {next_req.addr[ADDR_WIDTH-1:M], {M{1'b0}}};
                        mem_io.req_write_en = 0;
                    end
                end
            end
            WRITEBACK: begin
                addr_to_cache = pending_req.addr;
                mem_io.req_valid = 1;
                mem_io.req_addr = {pending_req.addr[ADDR_WIDTH-1:M], {M{1'b0}}};
                mem_io.req_write_en = 0;
            end
            WRITE: begin
                addr_to_cache = pending_req.addr;
                core_io.resp_valid = 1;
                write_to_cache = 1;
                write_data_to_cache = {96'b0, pending_req.data};
            end
        endcase
    end

endmodule
