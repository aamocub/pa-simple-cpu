module if_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input  logic          clk_i,  // Clock signal
    input  logic          rst_i,  // Reset signal
    input  cu_if_t        cu_i,   // Control data being sent by the control unit
    output if_stage_t     if_o,   // Output data from the IF stage
           memory_intf.CL mem_io  // Memory interface
);
    enum {
        RST,
        IF1,
        IF2
    } state;

    logic [PHY_ADDR_LEN-1:0] pc, next_pc;
    instruction_t instr, next_instr;


    always_ff @(posedge clk_i, posedge rst_i) begin : transitions_block
        if (rst_i) begin
            pc <= next_pc;
            state <= RST;
        end else begin
            pc <= next_pc;
            unique case (state)
                RST: state <= IF1;
                IF1: state <= IF2;
                IF2: state <= IF2;
            endcase
        end
    end

    always_comb begin : if_out
        if (cu_i.flush) begin
            if_o.pc = 0;
            if_o.instr = NOP_INSTR;
        end else if (cu_i.stall) begin
            if_o.pc = pc;
            if_o.instr = instr;
        end else begin
            if_o.pc = pc;
            if_o.instr = instr;
            if (!mem_io.resp_valid) begin
                if_o.instr = NOP_INSTR;
            end
        end
    end
    always_comb begin : generate_new_pc
        next_pc = pc;
        if (rst_i) begin
            next_pc = PC_RESET_ADDR;
        end else if (cu_i.stall) begin
            next_pc = pc;
        end else if (state == RST || state == IF1) begin
            next_pc = pc;
        end else begin
            if (mem_io.resp_valid) begin
                case (cu_i.taken)
                    0: next_pc = pc + 4;
                    1: next_pc = cu_i.addr;
                    default: next_pc = pc + 4;
                endcase
            end
        end
    end
    always_comb begin : fetch_pc_from_mem
        mem_io.req_write_en = 0;
        mem_io.req_valid = 0;
        mem_io.req_type = WORD;
        mem_io.req_addr = next_pc;
        if (rst_i) begin
            instr = NOP_INSTR;
        end else begin
            instr = instr;
            unique case (state)
                RST: ;
                IF1: begin
                    mem_io.req_valid = 1;
                end
                IF2: begin
                    if (mem_io.resp_valid) begin
                        instr = mem_io.resp_data;
                        mem_io.req_valid = 1;
                    end
                end
            endcase
        end
    end

endmodule
