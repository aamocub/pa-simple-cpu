module mem_arbitrer
    import pa_pkg::*;
    import riscv_pkg::*;
#(
    parameter integer unsigned ADDR_WIDTH = PHY_ADDR_LEN,
    parameter integer unsigned DATA_WIDTH = CACHE_LINE_LEN
) (
    input logic clk_i,
    input logic rst_i,

    memory_intf.SV icache_io,
    memory_intf.SV dcache_io,
    memory_intf.CL mem_read_io,
    memory_intf.CL mem_write_io
);
    typedef struct packed {
        logic valid;
        logic write_en;
        logic [ADDR_WIDTH-1:0] addr;
        logic [DATA_WIDTH-1:0] data;
    } req_t;

    logic if_busy;
    req_t if_pending;

    logic mm_read_busy;
    req_t mm_pending;

    // verilog_format: off
    enum { IF_IDLE, IF_PENDING, IF_BUSY } if_state;
    enum { MM_IDLE, MM_PENDING, MM_BUSY } mm_state;
    enum { WRITE_IDLE, WRITE_BUSY } write_state;
    // verilog_format: on

    function void send_if_req;
        if (if_pending.valid) begin
            mem_read_io.req_valid = if_pending.valid;
            mem_read_io.req_addr  = if_pending.addr;
        end else begin
            mem_read_io.req_valid = icache_io.req_valid;
            mem_read_io.req_addr  = icache_io.req_addr;
        end
    endfunction
    function void send_mm_req;
        if (mm_pending.valid) begin
            mem_read_io.req_valid = mm_pending.valid;
            mem_read_io.req_addr  = mm_pending.addr;
        end else begin
            mem_read_io.req_valid = dcache_io.req_valid;
            mem_read_io.req_addr  = dcache_io.req_addr;
        end
    endfunction
    function void recv_mm_resp;
        dcache_io.resp_valid = mem_read_io.resp_valid;
        dcache_io.resp_data  = mem_read_io.resp_data;
    endfunction
    function void recv_if_resp;
        icache_io.resp_valid = mem_read_io.resp_valid;
        icache_io.resp_data  = mem_read_io.resp_data;
    endfunction

    // Function used to send a new request to memory.
    function void send_new_req;
        mem_read_io.req_valid = 0;
        if (if_pending.valid) begin
            mem_read_io.req_valid = if_pending.valid;
            mem_read_io.req_addr  = if_pending.addr;
        end else if (mm_pending.valid) begin
            mem_read_io.req_valid = mm_pending.valid;
            mem_read_io.req_addr  = mm_pending.addr;
        end else if (icache_io.req_valid && dcache_io.req_valid) begin
            mem_read_io.req_valid = icache_io.req_valid;
            mem_read_io.req_addr  = icache_io.req_addr;
            // store MM read request on state transition block
        end else if (icache_io.req_valid) begin
            mem_read_io.req_valid = icache_io.req_valid;
            mem_read_io.req_addr  = icache_io.req_addr;
        end else if (dcache_io.req_valid) begin
            mem_read_io.req_valid = dcache_io.req_valid;
            mem_read_io.req_addr  = dcache_io.req_addr;
        end
    endfunction

    always_comb begin : mem_read_process
        icache_io.resp_valid = 0;
        dcache_io.resp_valid = 0;
        // verilog_format: off
        priority case ({ if_state, mm_state })
            { IF_IDLE, MM_IDLE } : begin
                send_new_req();
            end
            { IF_IDLE, MM_BUSY       }: begin
                if (mem_read_io.resp_valid) begin
                    recv_mm_resp();
                    send_new_req();
                end
            end
            { IF_PENDING, MM_BUSY    }: begin
                if (mem_read_io.resp_valid) begin
                    recv_mm_resp();
                    send_new_req();
                end
            end
            { IF_BUSY, MM_IDLE       }: begin
                if (mem_read_io.resp_valid) begin
                    recv_if_resp();
                    send_new_req();
                end
            end
            { IF_BUSY, MM_PENDING    }: begin
                if (mem_read_io.resp_valid) begin
                    recv_if_resp();
                    send_new_req();
                end
            end
        endcase
        // verilog_format: on
    end

    always_ff @(posedge clk_i, posedge rst_i) begin : mem_read_transitions
        if (rst_i) begin
            if_state <= IF_IDLE;
            mm_state <= MM_IDLE;
        end else begin
            // verilog_format: off
            priority case ({ if_state, mm_state })
                { IF_IDLE, MM_IDLE } : begin
                    if (icache_io.req_valid && dcache_io.req_valid) begin
                        if_state <= IF_BUSY;
                        mm_pending <= dcache_io.read_req;
                        mm_state <= MM_PENDING;
                    end else if (icache_io.req_valid) begin
                        if_state <= IF_BUSY;
                    end else if (dcache_io.req_valid) begin
                        if_state <= IF_BUSY;
                    end
                end
                { IF_IDLE, MM_BUSY }: begin
                    if (mem_read_io.resp_valid) begin
                        mm_state <= MM_IDLE;
                        if (icache_io.req_valid && dcache_io.req_valid) begin
                            if_state <= IF_BUSY;
                            mm_pending <= dcache_io.read_req;
                            mm_state <= MM_PENDING;
                        end else if (icache_io.req_valid) begin
                            if_state <= IF_BUSY;
                        end else if (dcache_io.req_valid) begin
                            if_state <= IF_BUSY;
                        end
                    end else begin
                        if (icache_io.req_valid) begin
                            if_state   <= IF_PENDING;
                            if_pending <= icache_io.read_req;
                        end
                    end
                end
                { IF_PENDING, MM_BUSY    }: begin
                    if (mem_read_io.resp_valid) begin
                        mm_state <= MM_IDLE;
                        if_state <= IF_BUSY;
                        if (dcache_io.req_valid) begin
                            mm_state <= MM_PENDING;
                            mm_pending <= dcache_io.read_req;
                        end
                    end
                end
                { IF_BUSY, MM_IDLE       }: begin
                    if (mem_read_io.resp_valid) begin
                        if_state <= IF_IDLE;
                        if (icache_io.req_valid && dcache_io.req_valid) begin
                            if_state <= IF_BUSY;
                            mm_pending <= dcache_io.read_req;
                            mm_state <= MM_PENDING;
                        end else if (icache_io.req_valid) begin
                            if_state <= IF_BUSY;
                        end else if (dcache_io.req_valid) begin
                            if_state <= IF_BUSY;
                        end
                    end else begin
                        if (dcache_io.req_valid) begin
                            mm_state   <= MM_PENDING;
                            mm_pending <= dcache_io.read_req;
                        end
                    end
                end
                { IF_BUSY, MM_PENDING    }: begin
                    if (mem_read_io.resp_valid) begin
                        if_state <= IF_IDLE;
                        mm_state <= MM_BUSY;
                        if (icache_io.req_valid) begin
                            if_state <= IF_PENDING;
                            if_pending <= icache_io.read_req;
                        end
                    end
                end
            endcase
            // verilog_format: on
        end
    end

    always_ff @(posedge clk_i, posedge rst_i) begin : mem_write_transitions
        if (rst_i) begin
            write_state <= WRITE_IDLE;
        end else begin
            unique case (write_state)
                WRITE_IDLE: begin
                    write_state <= dcache_io.req_valid && dcache_io.req_write_en ? WRITE_BUSY : 
                                                                                   write_state;
                end
                WRITE_BUSY: begin
                    if (mem_write_io.write_resp.valid && dcache_io.req_valid && dcache_io.req_write_en) begin
                        write_state <= WRITE_BUSY;
                    end else if (mem_write_io.resp_valid) begin
                        write_state <= WRITE_IDLE;
                    end else begin
                        write_state <= write_state;
                    end
                end
            endcase
        end
    end
    always_comb begin : mem_write_process
        mem_write_io.req_valid = 0;
        unique case (write_state)
            WRITE_IDLE: begin
                if (dcache_io.req_write_en) begin
                    mem_write_io.req_valid = dcache_io.req_valid;
                    mem_write_io.req_addr  = dcache_io.req_addr;
                    mem_write_io.req_data  = dcache_io.req_data;
                end
            end
            WRITE_BUSY: begin
                mem_write_io.req_valid = 0;
                dcache_io.resp_valid   = mem_write_io.resp_valid;
                if (mem_write_io.resp_valid) begin
                    if (dcache_io.req_valid && dcache_io.req_write_en) begin
                        mem_write_io.req_valid = dcache_io.req_valid;
                        mem_write_io.req_addr  = dcache_io.req_addr;
                        mem_write_io.req_data  = dcache_io.req_data;
                    end
                end
            end
        endcase
    end
endmodule
