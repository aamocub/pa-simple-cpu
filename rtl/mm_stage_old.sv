// Like in many other modules, MM stage communicates with memory through requests and responses.
// On REQ state:
//      Passthrough all non-memory related data onto next stage.
//      If the instruction is a ld or st then send a mem request and set state to RESP.
// On RESP state:
//      Set stall and wait for response of memory.
//      When receiving the response, disable the stall.
//      Set state back to REQ.

// This is a typical communication system.
// However, we want to cover an extra case: What if, on the same cycle that we receive a response we also receive a new request ?
// With the previous design we would have to wait one cycle in order to serve the requests, which is not desirable.
// So some other changes are in order:
// On RESP state:
//      IF we also receive a request when receiving the response, then we should send it.
// On REQ state:
//      IF we have sent a request on RESP state, we should receive it, so we should wait for its response.

module mm_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input logic clk_i,
    input logic rst_i,
    input ex_stage_t ex_i,
    output mm_read_req_t read_req_o,
    input mm_read_resp_t read_resp_i,
    output mm_write_req_t write_req_o,
    input mm_write_resp_t write_resp_i,
    output mm_stage_t mm_o
);

    enum {
        REQ,  // Request to memory and wait for response
        RESP  // Response from memory
    } state;

    logic resp_valid = read_resp_i.valid | write_resp_i.valid;

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            state <= REQ;
        end else begin
            unique case (state)
                REQ:  state <= resp_valid ? RESP : state;
                RESP: state <= REQ;
            endcase
        end
    end

    always_comb begin
        mm_o.rd = ex_i.rd;
        mm_o.is_wb = ex_i.is_wb;
        mm_o.data_rs2 = ex_i.data_rs2;
        mm_o.data = ex_i.alu_result;
        mm_o.do_stall = 0;
        unique case (state)
            REQ: begin
                if (ex_i.is_ld) begin
                    read_req_o.valid = 1;
                    read_req_o.addr  = ex_i.alu_result;
                end else begin
                    write_req_o.valid = 1;
                    write_req_o.addr  = ex_i.alu_result;
                    write_req_o.data  = ex_i.data_rs2;
                end
                mm_o.do_stall = 1;
            end
            RESP: begin
                if (ex_i.is_ld) begin
                    mm_o.data = read_resp_i.data;
                end
                mm_o.do_stall = 0;
            end
        endcase
    end

endmodule
