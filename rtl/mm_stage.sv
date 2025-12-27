module mm_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input  logic      clk_i,
    input  logic      rst_i,
    input  ex_stage_t ex_i,
    output mm_stage_t mm_o,

    cache_intf cache_io
);

    enum {
        REQ,  // Request to memory and wait for response
        RESP  // Response from memory
    } state;

    mm_read_req_t current_read;
    mm_write_req_t current_write;

    always_comb begin : passthrough_signals
        mm_o.rd       = ex_i.rd;
        mm_o.rs1      = ex_i.rs1;
        mm_o.rs2      = ex_i.rs2;
        mm_o.is_wb    = ex_i.is_wb;
        mm_o.data_rs2 = ex_i.data_rs2;
    end

    always_ff @(posedge clk_i, posedge rst_i) begin : transitions
        if (rst_i) begin
            state <= REQ;
        end else begin
            unique case (state)
                REQ: begin
                    state <= (ex_i.is_ld | ex_i.is_st) ? RESP : state;
                    if (ex_i.is_ld) begin
                        // current_read.valid <= 1;
                        // current_read.addr  <= ex_i.alu_result;
                    end else if (ex_i.is_st) begin
                        // current_write.valid <= 1;
                        // current_write.addr  <= ex_i.alu_result;
                        // current_write.data  <= ex_i.data_rs2;
                    end
                end
                RESP: begin
                    state <= cache_io.resp.valid ? REQ : state;
                end
            endcase
        end
    end

    always_comb begin
        cache_io.req.valid = 0;
        mm_o.do_stall      = 0;
        mm_o.data          = ex_i.alu_result;
        if (!rst_i) begin
            unique case (state)
                REQ: begin
                    if (ex_i.is_ld) begin
                        cache_io.req.valid = 1;
                        cache_io.req.kind = READ;
                        cache_io.req.addr = ex_i.alu_result;
                        mm_o.do_stall = 1;
                    end else if (ex_i.is_st) begin
                        cache_io.req.valid = 1;
                        cache_io.req.kind = WRITE;
                        cache_io.req.addr = ex_i.alu_result;
                        cache_io.req.data = ex_i.data_rs2;
                        mm_o.do_stall = 1;
                    end
                end
                RESP: begin
                    mm_o.do_stall = 1;
                    // cache_io.req.valid = 0;
                    if (cache_io.resp.valid) begin
                        mm_o.do_stall = 0;
                        mm_o.data = cache_io.resp.data;
                        unique case (ex_i.mem_width)
                            BYTE:  mm_o.data = {{24{cache_io.resp.data[31]}}, cache_io.resp.data[31:24]};
                            UBYTE: mm_o.data = {24'b0, cache_io.resp.data[31:24]};
                            HALF:  mm_o.data = {{16{cache_io.resp.data[31]}}, cache_io.resp.data[31:16]};
                            UHALF: mm_o.data = {16'b0, cache_io.resp.data[31:16]};
                            WORD:  mm_o.data = {cache_io.resp.data};
                        endcase
                    end
                end
            endcase
        end
    end

endmodule
