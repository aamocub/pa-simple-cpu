//// IF stage state machine
// 1. Generates new PC
// 2. Requests memory for instruction in PC
// 3. Waits for result
// 4. Sends result to if_o
// 5. Go to step 1

// TODO: make this a 1-cycle stage

module if_stage
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input  logic      clk_i,   // Clock signal
    input  logic      rst_i,   // Reset signal
    input  cu_if_t    ctrl_i,  // Control data being sent by the control unit
    output if_req_t   req_o,   // Request new instruction to memory
    input  if_resp_t  resp_i,  // Response from memory with new instruction
    output if_stage_t if_o     // Output data from the IF stage
);
    // verilog_format: off
    enum { PC_GEN, PC_FETCH } state;
    // verilog_format: on

    logic [PHY_ADDR_LEN-1:0] pc;
    logic [PHY_ADDR_LEN-1:0] next_pc;

    always_comb begin
        if (ctrl_i.flush) begin
            if_o.instr = NOP_INSTR;
        end else begin
            unique case (state)
                PC_GEN: begin
                    if (rst_i) begin
                        pc = PC_RESET_ADDR;
                        next_pc = PC_RESET_ADDR;
                    end else begin
                        case (ctrl_i.taken)
                            0: next_pc = pc + 4;
                            1: next_pc = ctrl_i.addr;
                        endcase
                        pc = next_pc;
                        req_o.valid = 1;
                        req_o.addr = next_pc;
                    end
                end
                PC_FETCH: begin
                    if (resp_i.valid) begin
                        req_o.valid = 0;
                        if_o.instr  = resp_i.data;
                    end else begin
                        if_o.instr = NOP_INSTR;
                    end
                end
            endcase
        end
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            state <= PC_GEN;
        end else begin
            unique case (state)
                PC_GEN:   state <= PC_FETCH;
                PC_FETCH: state <= resp_i.valid ? PC_GEN : state;
            endcase
        end
    end

endmodule
