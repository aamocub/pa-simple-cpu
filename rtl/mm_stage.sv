module mm_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input  logic           clk_i,
    input  logic           rst_i,
    input  ex_stage_t      ex_i,
    output mm_read_req_t   read_req_o,
    input  mm_read_resp_t  read_resp_i,
    output mm_write_req_t  write_req_o,
    input  mm_write_resp_t write_resp_i,
    output mm_stage_t      mm_o
);

    enum {
        REQ,  // Request to memory and wait for response
        RESP  // Response from memory
    } state;

    mm_read_req_t current_read;
    mm_write_req_t current_write;

    always_comb begin : exceptions
        mm_o.evec = ex_i.evec;
    end
    always_comb begin : passthrough_signals
        mm_o.rd       = ex_i.rd;
        mm_o.rs1      = ex_i.rs1;
        mm_o.rs2      = ex_i.rs2;
        mm_o.pc       = ex_i.pc;
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
                    state <= (read_resp_i.valid | write_resp_i.valid) ? REQ : state;
                end
            endcase
        end
    end

    always_comb begin
        read_req_o    = '{default: 0};
        write_req_o   = '{default: 0};
        mm_o.do_stall = 0;
        mm_o.data     = ex_i.alu_result;
        if (!rst_i) begin
            unique case (state)
                REQ: begin
                    if (ex_i.is_ld) begin
                        read_req_o.valid = 1;
                        read_req_o.addr = ex_i.alu_result;
                        mm_o.do_stall = 1;
                    end else if (ex_i.is_st) begin
                        write_req_o.valid = 1;
                        write_req_o.addr = ex_i.alu_result;
                        write_req_o.data = ex_i.data_rs2;
                        mm_o.do_stall = 1;
                    end
                end
                RESP: begin
                    mm_o.do_stall = 1;
                    // write_req_o.valid = 0;
                    // read_req_o.valid = 0;
                    if (read_resp_i.valid) begin
                        mm_o.do_stall = 0;
                        mm_o.data = read_resp_i.data;
                        unique case (ex_i.mem_width)
                            BYTE:  mm_o.data = {{24{read_resp_i.data[31]}}, read_resp_i.data[31:24]};
                            UBYTE: mm_o.data = {24'b0, read_resp_i.data[31:24]};
                            HALF:  mm_o.data = {{16{read_resp_i.data[31]}}, read_resp_i.data[31:16]};
                            UHALF: mm_o.data = {16'b0, read_resp_i.data[31:16]};
                            WORD:  mm_o.data = {<<8{read_resp_i.data}};
                        endcase
                    end
                end
            endcase
        end
    end

endmodule
