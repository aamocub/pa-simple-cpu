//// IF stage state machine
// 1. Generates new PC
// 2. Requests memory for instruction in PC
// 3. Waits for result
// 4. Sends result to if_o
// 5. Go to step 1

module if_stage
    import pa_pkg::*;
    import riscv_pkg::*;
#(
) (
    input  logic      clk_i,   // Clock signal
    input  logic      rst_i,   // Reset signal
    input  ctrl_if_t  ctrl_i,  // Control signals
    output if_req_t   req_o,   // Memory request
    input  if_resp_t  resp_i,  // Memory response
    output if_stage_t if_o     // Fetched instruction
);
    // verilog_format: off
    enum { IDLE, PC_GEN, PC_RESP } state;
    // verilog_format: on

    logic [PHY_ADDR_LEN-1:0] pc;
    logic [PHY_ADDR_LEN-1:0] next_pc;

    always_comb begin
        case (state)
            IDLE: begin
                pc <= PC_RESET_ADDR;
                next_pc <= PC_RESET_ADDR;
            end
            PC_GEN: begin
                case (ctrl_i.pc_sel)
                    0: next_pc <= pc + 4;
                    1: next_pc <= pc + 4;
                endcase
                pc <= next_pc;
                req_o.valid <= 1;
                req_o.addr <= next_pc;
            end
            PC_RESP: begin
                if (resp_i.valid) begin
                    req_o.valid <= 0;
                    if_o.instr  <= resp_i.data;
                end else begin
                    if_o.instr <= '0;
                end
            end
            default: ;
        endcase
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
        end else begin
            unique case (state)
                IDLE: state <= PC_GEN;
                PC_GEN: state <= PC_RESP;
                PC_RESP: state <= resp_i.valid ? PC_GEN : state;
                default: state <= state;
            endcase
        end
    end

endmodule
