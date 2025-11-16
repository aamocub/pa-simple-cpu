//// IF stage state machine
// 1. Generates new PC
// 2. Requests memory for instruction in PC
// 3. Waits for result
// 4. Sends result to if_o
// 5. Go to step 1

// TODO: make this a 1-cycle stage or not

module if_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input  logic      clk_i,   // Clock signal
    input  logic      rst_i,   // Reset signal
    input  cu_if_t    ctrl_i,  // Control data being sent by the control unit
    output if_req_t   req_o,   // Request new instruction to memory
    input  if_resp_t  resp_i,  // Response from memory with new instruction
    output if_stage_t if_o     // Output data from the IF stage
);
    // verilog_format: off
    enum { RST, IDLE, PC_GEN, PC_FETCH } state;
    // verilog_format: on

    logic [PHY_ADDR_LEN-1:0] pc;
    logic [PHY_ADDR_LEN-1:0] next_pc;

    always_comb begin
        if (rst_i) begin
            if_o.instr = NOP_INSTR;
            next_pc = pc;
        end else begin
            priority case (state)
                RST: ;
                IDLE: begin
                    req_o.addr  = pc;
                    req_o.valid = 1;
                end
                PC_GEN: begin
                    case (ctrl_i.taken)
                        0: next_pc = pc + 4;
                        1: next_pc = ctrl_i.addr;
                    endcase
                    req_o.addr  = next_pc;
                    req_o.valid = 1;
                    if (resp_i.valid) begin
                        if_o.instr = resp_i.data;
                    end
                end
                PC_FETCH: begin
                    req_o.valid = 0;
                    if (resp_i.valid) begin
                        if_o.instr = resp_i.data;
                        case (ctrl_i.taken)
                            0: next_pc = pc + 4;
                            1: next_pc = ctrl_i.addr;
                        endcase
                        req_o.addr  = next_pc;
                        req_o.valid = 1;
                    end else begin
                        if_o.instr = NOP_INSTR;
                    end
                end
            endcase
            if (ctrl_i.flush) begin
                if_o.instr = NOP_INSTR;
            end
        end
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            state <= RST;
            pc <= PC_RESET_ADDR;
        end else begin
            pc <= next_pc;
            unique case (state)
                RST: state <= IDLE;
                IDLE, PC_GEN: begin
                    state <= PC_FETCH;
                end
                PC_FETCH: begin
                    state <= resp_i.valid ? PC_GEN : state;
                end
            endcase
        end
    end

endmodule
