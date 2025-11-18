module mem_arbitrer
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input logic clk_i,
    input logic rst_i,

    // To/From CORE -->
    input  if_req_t        if_req_i,
    output if_resp_t       if_resp_o,
    input  mm_read_req_t   mm_read_req_i,
    output mm_read_resp_t  mm_read_resp_o,
    input  mm_write_req_t  mm_write_req_i,
    output mm_write_resp_t mm_write_resp_o,

    // To/From MEMORY -->
    output mem_write_req_t  mem_write_req_o,
    input  mem_write_resp_t mem_write_resp_i,
    output mem_read_req_t   mem_read_req_o,
    input  mem_read_resp_t  mem_read_resp_i
);

    logic if_busy;
    if_req_t if_pending;

    logic mm_read_busy;
    mm_read_req_t mm_pending;
    reg test;

    // verilog_format: off
    enum { IF_IDLE, IF_PENDING, IF_BUSY } if_state;
    enum { MM_IDLE, MM_PENDING, MM_BUSY } mm_state;
    // verilog_format: on

    function void send_if_req;
        if (if_pending.valid) begin
            mem_read_req_o.valid = if_pending.valid;
            mem_read_req_o.addr  = if_pending.addr;
        end else begin
            mem_read_req_o.valid = if_req_i.valid;
            mem_read_req_o.addr  = if_req_i.addr;
        end
    endfunction
    function void send_mm_req;
        if (mm_pending.valid) begin
            mem_read_req_o.valid = mm_pending.valid;
            mem_read_req_o.addr  = mm_pending.addr;
        end else begin
            mem_read_req_o.valid = mm_read_req_i.valid;
            mem_read_req_o.addr  = mm_read_req_i.addr;
        end
    endfunction
    function void recv_mm_resp;
        mm_read_resp_o.valid = mem_read_resp_i.valid;
        mm_read_resp_o.data  = mem_read_resp_i.data;
    endfunction
    function void recv_if_resp;
        if_resp_o.valid = mem_read_resp_i.valid;
        if_resp_o.data  = mem_read_resp_i.data;
    endfunction

    // Function used to send a new request to memory.
    function void send_new_req;
        mem_read_req_o.valid = 0;
        if (if_pending.valid) begin
            mem_read_req_o.valid = if_pending.valid;
            mem_read_req_o.addr  = if_pending.addr;
        end else if (mm_pending.valid) begin
            mem_read_req_o.valid = mm_pending.valid;
            mem_read_req_o.addr  = mm_pending.addr;
        end else if (if_req_i.valid && mm_read_req_i.valid) begin
            mem_read_req_o.valid = if_req_i.valid;
            mem_read_req_o.addr  = if_req_i.addr;
            // store MM read request on state transition block
        end else if (if_req_i.valid) begin
            mem_read_req_o.valid = if_req_i.valid;
            mem_read_req_o.addr  = if_req_i.addr;
        end else if (mm_read_req_i.valid) begin
            mem_read_req_o.valid = mm_read_req_i.valid;
            mem_read_req_o.addr  = mm_read_req_i.addr;
        end
    endfunction

    always_comb begin : automata
        if_resp_o.valid       = 0;
        mm_read_resp_o.valid  = 0;
        mm_write_resp_o.valid = 0;
        // verilog_format: off
        priority case ({ if_state, mm_state })
            { IF_IDLE, MM_IDLE } : begin
                send_new_req();
            end
            { IF_IDLE, MM_BUSY       }: begin
                if (mem_read_resp_i.valid) begin
                    recv_mm_resp();
                    send_new_req();
                end
            end
            { IF_PENDING, MM_BUSY    }: begin
                if (mem_read_resp_i.valid) begin
                    recv_mm_resp();
                    send_new_req();
                end
            end
            { IF_BUSY, MM_IDLE       }: begin
                if (mem_read_resp_i.valid) begin
                    recv_if_resp();
                    send_new_req();
                end
            end
            { IF_BUSY, MM_PENDING    }: begin
                if (mem_read_resp_i.valid) begin
                    recv_if_resp();
                    send_new_req();
                end
            end
        endcase
        // verilog_format: on
    end

    always_ff @(posedge clk_i, posedge rst_i) begin : transitions
        if (rst_i) begin
            if_state <= IF_IDLE;
            mm_state <= MM_IDLE;
        end else begin
            // verilog_format: off
            priority case ({ if_state, mm_state })
                { IF_IDLE, MM_IDLE } : begin
                    if (if_req_i.valid) begin
                        if_state <= IF_BUSY;
                    end else if (mm_read_req_i.valid) begin
                        mm_state <= MM_BUSY;
                    end
                    if (mm_read_req_i.valid && if_req_i.valid) begin
                        mm_state <= MM_PENDING;
                        mm_pending <= mm_read_req_i;
                    end
                end
                { IF_IDLE, MM_BUSY }: begin
                    if (if_req_i.valid) begin
                        if_state   <= IF_PENDING;
                        if_pending <= if_req_i;
                    end
                    if (mem_read_resp_i.valid) begin
                        mm_state <= MM_IDLE;
                        if (if_req_i.valid) if_state <= IF_BUSY;
                    end
                end
                { IF_PENDING, MM_BUSY    }: begin
                    if (mem_read_resp_i.valid) begin
                        mm_state <= MM_IDLE;
                        if_state <= IF_BUSY;
                    end
                end
                { IF_BUSY, MM_IDLE       }: begin
                    if (mem_read_resp_i.valid) begin
                        if_state <= IF_IDLE;
                        if (if_req_i.valid) if_state <= IF_BUSY;
                        else if (mm_read_req_i.valid) mm_state <= MM_BUSY;
                    end
                    if (mm_read_req_i.valid) begin
                        mm_state   <= MM_PENDING;
                        mm_pending <= mm_read_req_i;
                    end
                end
                { IF_BUSY, MM_PENDING    }: begin
                    if (mem_read_resp_i.valid) begin
                        if_state <= IF_IDLE;
                        mm_state <= MM_BUSY;
                    end
                end
            endcase
            // verilog_format: on
        end
    end
endmodule
