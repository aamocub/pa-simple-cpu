module mem_arbitrer
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input logic clk_i,
    input logic rst_i,

    memory_intf icache_io,
    memory_intf dcache_io,
    memory_intf mem_io
);

    logic if_busy;
    mem_read_req_t if_pending;

    logic mm_read_busy;
    mem_read_req_t mm_pending;
    reg test;

    // verilog_format: off
    enum { IF_IDLE, IF_PENDING, IF_BUSY } if_state;
    enum { MM_IDLE, MM_PENDING, MM_BUSY } mm_state;
    enum { WRITE_IDLE, WRITE_BUSY } write_state;
    // verilog_format: on

    function void send_if_req;
        if (if_pending.valid) begin
            mem_io.read_req.valid = if_pending.valid;
            mem_io.read_req.addr  = if_pending.addr;
        end else begin
            mem_io.read_req.valid = icache_io.read_req.valid;
            mem_io.read_req.addr  = icache_io.read_req.addr;
        end
    endfunction
    function void send_mm_req;
        if (mm_pending.valid) begin
            mem_io.read_req.valid = mm_pending.valid;
            mem_io.read_req.addr  = mm_pending.addr;
        end else begin
            mem_io.read_req.valid = dcache_io.read_req.valid;
            mem_io.read_req.addr  = dcache_io.read_req.addr;
        end
    endfunction
    function void recv_mm_resp;
        dcache_io.read_resp.valid = mem_io.read_resp.valid;
        dcache_io.read_resp.data  = mem_io.read_resp.data;
    endfunction
    function void recv_if_resp;
        icache_io.read_resp.valid = mem_io.read_resp.valid;
        icache_io.read_resp.data  = mem_io.read_resp.data;
    endfunction

    // Function used to send a new request to memory.
    function void send_new_req;
        mem_io.read_req.valid = 0;
        if (if_pending.valid) begin
            mem_io.read_req.valid = if_pending.valid;
            mem_io.read_req.addr  = if_pending.addr;
        end else if (mm_pending.valid) begin
            mem_io.read_req.valid = mm_pending.valid;
            mem_io.read_req.addr  = mm_pending.addr;
        end else if (icache_io.read_req.valid && dcache_io.read_req.valid) begin
            mem_io.read_req.valid = icache_io.read_req.valid;
            mem_io.read_req.addr  = icache_io.read_req.addr;
            // store MM read request on state transition block
        end else if (icache_io.read_req.valid) begin
            mem_io.read_req.valid = icache_io.read_req.valid;
            mem_io.read_req.addr  = icache_io.read_req.addr;
        end else if (dcache_io.read_req.valid) begin
            mem_io.read_req.valid = dcache_io.read_req.valid;
            mem_io.read_req.addr  = dcache_io.read_req.addr;
        end
    endfunction

    always_comb begin : mem_read_process
        icache_io.read_resp.valid = 0;
        dcache_io.read_resp.valid = 0;
        // verilog_format: off
        priority case ({ if_state, mm_state })
            { IF_IDLE, MM_IDLE } : begin
                send_new_req();
            end
            { IF_IDLE, MM_BUSY       }: begin
                if (mem_io.read_resp.valid) begin
                    recv_mm_resp();
                    send_new_req();
                end
            end
            { IF_PENDING, MM_BUSY    }: begin
                if (mem_io.read_resp.valid) begin
                    recv_mm_resp();
                    send_new_req();
                end
            end
            { IF_BUSY, MM_IDLE       }: begin
                if (mem_io.read_resp.valid) begin
                    recv_if_resp();
                    send_new_req();
                end
            end
            { IF_BUSY, MM_PENDING    }: begin
                if (mem_io.read_resp.valid) begin
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
                    if (icache_io.read_req.valid && dcache_io.read_req.valid) begin
                        if_state <= IF_BUSY;
                        mm_pending <= dcache_io.read_req;
                        mm_state <= MM_PENDING;
                    end else if (icache_io.read_req.valid) begin
                        if_state <= IF_BUSY;
                    end else if (dcache_io.read_req.valid) begin
                        if_state <= IF_BUSY;
                    end
                end
                { IF_IDLE, MM_BUSY }: begin
                    if (mem_io.read_resp.valid) begin
                        mm_state <= MM_IDLE;
                        if (icache_io.read_req.valid && dcache_io.read_req.valid) begin
                            if_state <= IF_BUSY;
                            mm_pending <= dcache_io.read_req;
                            mm_state <= MM_PENDING;
                        end else if (icache_io.read_req.valid) begin
                            if_state <= IF_BUSY;
                        end else if (dcache_io.read_req.valid) begin
                            if_state <= IF_BUSY;
                        end
                    end else begin
                        if (icache_io.read_req.valid) begin
                            if_state   <= IF_PENDING;
                            if_pending <= icache_io.read_req;
                        end
                    end
                end
                { IF_PENDING, MM_BUSY    }: begin
                    if (mem_io.read_resp.valid) begin
                        mm_state <= MM_IDLE;
                        if_state <= IF_BUSY;
                        if (dcache_io.read_req.valid) begin
                            mm_state <= MM_PENDING;
                            mm_pending <= dcache_io.read_req;
                        end
                    end
                end
                { IF_BUSY, MM_IDLE       }: begin
                    if (mem_io.read_resp.valid) begin
                        if_state <= IF_IDLE;
                        if (icache_io.read_req.valid && dcache_io.read_req.valid) begin
                            if_state <= IF_BUSY;
                            mm_pending <= dcache_io.read_req;
                            mm_state <= MM_PENDING;
                        end else if (icache_io.read_req.valid) begin
                            if_state <= IF_BUSY;
                        end else if (dcache_io.read_req.valid) begin
                            if_state <= IF_BUSY;
                        end
                    end else begin
                        if (dcache_io.read_req.valid) begin
                            mm_state   <= MM_PENDING;
                            mm_pending <= dcache_io.read_req;
                        end
                    end
                end
                { IF_BUSY, MM_PENDING    }: begin
                    if (mem_io.read_resp.valid) begin
                        if_state <= IF_IDLE;
                        mm_state <= MM_BUSY;
                        if (icache_io.read_req.valid) begin
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
                WRITE_IDLE: write_state <= dcache_io.write_req.valid ? WRITE_BUSY : write_state;
                WRITE_BUSY: begin
                    if (mem_io.write_resp.valid && dcache_io.write_req.valid) begin
                        write_state <= WRITE_BUSY;
                    end else if (mem_io.write_resp.valid) begin
                        write_state <= WRITE_IDLE;
                    end else begin
                        write_state <= write_state;
                    end
                end
            endcase
        end
    end
    always_comb begin : mem_write_process
        mem_io.write_req.valid = 0;
        unique case (write_state)
            WRITE_IDLE: begin
                mem_io.write_req.valid = dcache_io.write_req.valid;
                mem_io.write_req.addr  = dcache_io.write_req.addr;
                mem_io.write_req.data  = dcache_io.write_req.data;
            end
            WRITE_BUSY: begin
                mem_io.write_req.valid = 0;
                dcache_io.write_resp.valid = mem_io.write_resp.valid;
                if (mem_io.write_resp.valid) begin
                    if (dcache_io.write_req.valid) begin
                        mem_io.write_req.valid = dcache_io.write_req.valid;
                        mem_io.write_req.addr  = dcache_io.write_req.addr;
                        mem_io.write_req.data  = dcache_io.write_req.data;
                    end
                end
            end
        endcase
    end
endmodule
