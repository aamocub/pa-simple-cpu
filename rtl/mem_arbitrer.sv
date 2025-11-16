// TODO: El dato que recibe arbitrer de memoria no se pasa directamente a IF o MM,
// sino que tarda un ciclo de más. Hay que mover la logica fuera del `always_ff` y
// hacerla combinacional

// TODO: Hay que implementar un sistema de prioridad que permita servir a la etapa MM
// porque, si no, la etapa IF acapara todos los accesos

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

    always_comb begin
        if_resp_o.valid       = 0;
        mm_read_resp_o.valid  = 0;
        mm_write_resp_o.valid = 0;
        // verilog_format: off
        priority case ({ if_state, mm_state })
            { IF_IDLE, MM_IDLE } : begin
                if (if_req_i.valid) begin
                    mem_read_req_o.valid = 1;
                    mem_read_req_o.addr  = if_req_i.addr;
                end else if (mm_read_req_i.valid) begin
                    mem_read_req_o.valid = 1;
                    mem_read_req_o.addr  = mm_read_req_i.addr;
                end
            end
            { IF_IDLE, MM_BUSY       }: begin
                if (mem_read_resp_i.valid) begin
                    mm_read_resp_o.valid = 1;
                    mm_read_resp_o.data  = mem_read_resp_i.data;

                    mem_read_req_o.valid = if_req_i.valid;
                    mem_read_req_o.addr  = if_req_i.addr;
                end
            end
            { IF_PENDING, MM_BUSY    }: begin
                if (mem_read_resp_i.valid) begin
                    mm_read_resp_o.valid = 1;
                    mm_read_resp_o.data  = mem_read_resp_i.data;

                    mem_read_req_o.valid = 1;
                    mem_read_req_o.addr  = if_pending.addr;
                end
            end
            { IF_BUSY, MM_IDLE       }: begin
                if (mem_read_resp_i.valid) begin
                    if_resp_o.valid = 1;
                    if_resp_o.data  = mem_read_resp_i.data;

                    if (if_req_i.valid) begin
                        mem_read_req_o.valid = 1;
                        mem_read_req_o.addr  = if_req_i.addr;
                    end else if (mm_read_req_i.valid) begin
                        mem_read_req_o.valid = 1;
                        mem_read_req_o.addr  = mm_read_req_i.addr;
                    end
                end
            end
            { IF_BUSY, MM_PENDING    }: begin
                if (mem_read_resp_i.valid) begin
                    if_resp_o.valid = 1;
                    if_resp_o.data  = mem_read_resp_i.data;

                    mem_read_req_o.valid = 1;
                    mem_read_req_o.addr  = mm_pending.addr;
                end
            end
        endcase
        // verilog_format: on
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
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

    /*
    always_comb begin
        if (rst_i) begin
            if_pending = '{default: 0};
            mm_pending = '{default: 0};
        end else begin
            if (if_busy && mem_read_resp_i.valid) begin
                if_busy = 0;
                if_pending = '{default: 0};
                mem_read_req_o.valid = 0;
            end else if (if_pending.valid && !mm_read_busy) begin
                if_busy = 1;
                mem_read_req_o.valid = 1;
                mem_read_req_o.addr = if_pending.addr;
            end else if (if_req_i.valid && !mm_read_busy) begin
                mem_read_req_o.valid = 1;
                mem_read_req_o.addr = if_req_i.addr;
                if_busy = 1;
            end else if (if_req_i.valid && mm_read_busy) begin
                if_pending = if_req_i;
            end
            if (mm_read_busy && mem_read_resp_i.valid) begin
                mm_read_busy = 0;
                mm_pending = '{default: 0};
                mem_read_req_o.valid = 0;
            end else if (mm_pending.valid && !if_busy) begin
                mm_read_busy = 1;
                mem_read_req_o.valid = 1;
                mem_read_req_o.addr = mm_pending.addr;
            end else if (mm_read_req_i.valid && !if_busy && !if_pending.valid) begin
                mem_read_req_o.valid = 1;
                mem_read_req_o.addr = mm_read_req_i.addr;
                mm_read_busy = 1;
            end else if (mm_read_req_i.valid && (if_busy || if_pending.valid)) begin
                mm_pending = mm_read_req_i;
            end
        end
    end
    */

    // always_ff @(posedge clk_i, posedge rst_i) begin
    //     mm_read_busy               <= 0;
    //     // mem_read_req_o.valid  <= 0;
    //     mem_write_req_o.valid <= 0;
    //     if_resp_o.data        <= 0;

    //     if (if_req_i.valid && !mm_read_busy) begin
    //         // mem_read_req_o.valid   <= 1;
    //         // mem_read_req_o.addr    <= if_req_i.addr;
    //         mem_read_req_o.byte_en <= 15;
    //         // if_busy                <= !mem_read_resp_i.valid;
    //         if_resp_o.valid        <= mem_read_resp_i.valid;
    //         if_resp_o.data         <= mem_read_resp_i.data;
    //     end else if (mm_read_req_i.valid && !if_busy) begin
    //         // mem_read_req_o.valid <= 1;
    //         // mem_read_req_o.addr  <= mm_read_req_i.addr;
    //         mm_read_busy              <= !mem_read_resp_i.valid;
    //         mm_read_resp_o.valid <= mem_read_resp_i.valid;
    //         mm_read_resp_o.data  <= mem_read_resp_i.data;
    //     end

    //     if (mm_write_req_i.valid) begin
    //         mem_write_req_o.valid <= 1;
    //         mem_write_req_o.addr  <= mm_write_req_i.addr;
    //         mem_write_req_o.data  <= mm_write_req_i.data;
    //         mm_write_resp_o.valid <= mem_write_resp_i.valid;
    //     end
    // end

endmodule
