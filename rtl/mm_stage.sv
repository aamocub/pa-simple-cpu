module mm_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input  logic          clk_i,
    input  logic          rst_i,
    input  ex_stage_t     ex_i,
    output mm_stage_t     mm_o,
           memory_intf.CL mem_io
);

    enum {
        REQ,  // Request to memory and wait for response
        RESP  // Response from memory
    } state;

    always_comb begin : exceptions
        mm_o.evec = ex_i.evec;
    end

    always_comb begin : passthrough_signals
        mm_o.rd       = ex_i.rd;
        mm_o.rs1      = ex_i.rs1;
        mm_o.rs2      = ex_i.rs2;
        mm_o.pc       = ex_i.pc;
        mm_o.hf_id    = ex_i.hf_id;
        mm_o.is_wb    = ex_i.is_wb;
        mm_o.data_rs2 = ex_i.data_rs2;
    end

    always_ff @(posedge clk_i, posedge rst_i) begin : transitions
        if (rst_i) begin
            state <= REQ;
        end else if (!(|ex_i.evec)) begin
            unique case (state)
                REQ: begin
                    if (mem_io.resp_valid) begin
                        state <= REQ;
                    end else if (ex_i.is_ld || ex_i.is_st) begin
                        state <= RESP;
                    end else begin
                        state <= state;
                    end
                end
                RESP: begin
                    state <= mem_io.resp_valid ? REQ : state;
                end
            endcase
        end
    end

    always_comb begin
        mem_io.req_valid    = 0;
        mem_io.req_write_en = 0;
        mem_io.req_addr     = ex_i.alu_result;
        mem_io.req_type     = ex_i.mem_width;
        mem_io.req_data     = ex_i.data_rs2;
        mm_o.do_stall       = 0;
        mm_o.data           = ex_i.alu_result;
        if (!rst_i && !(|ex_i.evec)) begin
            unique case (state)
                REQ: begin
                    if (ex_i.is_ld) begin
                        mm_o.do_stall = 1;
                        mem_io.req_valid = 1;
                    end else if (ex_i.is_st) begin
                        mm_o.do_stall = 1;
                        mem_io.req_valid = 1;
                        mem_io.req_write_en = 1;
                    end
                    if (mem_io.resp_valid) begin
                        mm_o.do_stall = 0;
                        unique case (ex_i.mem_width)
                            BYTE:  mm_o.data = {{24{mem_io.resp_data[7]}}, mem_io.resp_data[7:0]};
                            UBYTE: mm_o.data = {24'b0, mem_io.resp_data[7:0]};
                            HALF:  mm_o.data = {{16{mem_io.resp_data[15]}}, mem_io.resp_data[15:0]};
                            UHALF: mm_o.data = {16'b0, mem_io.resp_data[15:0]};
                            WORD:  mm_o.data = {mem_io.resp_data};
                        endcase
                    end
                end
                RESP: begin
                    mm_o.do_stall = mem_io.resp_valid ? 0 : 1;
                    unique case (ex_i.mem_width)
                        BYTE:  mm_o.data = {{24{mem_io.resp_data[7]}}, mem_io.resp_data[7:0]};
                        UBYTE: mm_o.data = {24'b0, mem_io.resp_data[7:0]};
                        HALF:  mm_o.data = {{16{mem_io.resp_data[15]}}, mem_io.resp_data[15:0]};
                        UHALF: mm_o.data = {16'b0, mem_io.resp_data[15:0]};
                        WORD:  mm_o.data = {mem_io.resp_data};
                    endcase
                end
            endcase
        end
    end

endmodule
