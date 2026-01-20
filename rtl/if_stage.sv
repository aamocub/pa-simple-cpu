module if_stage
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter integer unsigned ADDR_WIDTH = PHY_ADDR_LEN
) (
    input logic clk_i,
    input logic rst_i,
    input cu_if_t cu_i,
    memory_intf.CL mem_io,
    output if_stage_t if_o
);
    //verilog_format: off
    enum { RST, FETCH, WAIT, JUMP } state;
    //verilog_format: on
    logic [ADDR_WIDTH-1:0] pc, next_pc, pend_addr;
    instruction_t instr;
    logic from_jump;

    always_comb begin
        if_o.pc    = pc;
        if_o.instr = instr;
        if_o.evec  = '0;
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
        pc <= next_pc;
        if (rst_i) begin
            state <= RST;
        end else begin
            from_jump <= 0;
            unique case (state)
                RST: begin
                    state <= FETCH;
                end
                FETCH: begin
                    state <= mem_io.resp_valid ? FETCH : WAIT;
                end
                WAIT: begin
                    if (cu_i.pcsel != 0) begin
                        pend_addr <= next_pc;
                        state <= JUMP;
                    end else if (mem_io.resp_valid) begin
                        state <= FETCH;
                    end else begin
                        state <= WAIT;
                    end
                end
                JUMP: begin
                    from_jump <= 1;
                    if (mem_io.resp_valid) begin
                        state <= FETCH;
                    end else begin
                        state <= JUMP;
                    end
                end
            endcase
        end
    end
    always_comb begin
        mem_io.req_write_en = 0;
        mem_io.req_valid = 0;
        mem_io.req_type = WORD;
        mem_io.req_addr = pc;
        instr = NOP_INSTR;
        unique case (state)
            RST: begin
            end
            FETCH: begin
                mem_io.req_valid = 1;
                if (from_jump) mem_io.req_addr = pend_addr;
                unique case (cu_i.pcsel)
                    0: mem_io.req_addr = pc;
                    1, 2: mem_io.req_addr = next_pc;
                endcase
                if (mem_io.resp_valid) instr = mem_io.resp_data;
            end
            WAIT: begin
                if (mem_io.resp_valid) instr = mem_io.resp_data;
            end
            JUMP: begin
            end
        endcase
    end
    always_comb begin
        if (rst_i) begin
            next_pc = PC_RESET_ADDR;
        end else begin
            if (cu_i.stall) begin
                next_pc = pc;
            end else begin
                next_pc = pc;
                unique case (state)
                    RST: begin
                    end
                    FETCH: begin
                        unique case (cu_i.pcsel)
                            0: next_pc = mem_io.resp_valid ? pc + 4 : pc;
                            1: next_pc = cu_i.addr;
                            2: next_pc = PC_EXCEPTION_ADDR;
                        endcase
                    end
                    WAIT: begin
                        unique case (cu_i.pcsel)
                            0: next_pc = mem_io.resp_valid ? pc + 4 : pc;
                            1: next_pc = cu_i.addr;
                            2: next_pc = PC_EXCEPTION_ADDR;
                        endcase
                    end
                    JUMP: begin
                        if (mem_io.resp_valid) begin
                            next_pc = pend_addr;
                        end
                    end
                endcase
            end
        end
    end

endmodule
