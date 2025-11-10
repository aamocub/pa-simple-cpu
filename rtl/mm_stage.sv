module mm_stage
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input logic clk_i,
    input logic rst_i,
    input ex_stage_t ex_i,
    output mm_stage_t mm_o
);


    enum {
        REQ,  // Request to memory and wait for response
        RESP,  // Response from memory
        NO  // Don't do anything
    } state;

    logic resp_valid = mm_o.read_resp.valid | mm_o.write_resp.valid;

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            state <= NO;
        end else begin
            unique case (state)
                NO:   state <= (ex_i.is_ld || ex_i.is_st) ? REQ : state;
                REQ:  state <= resp_valid ? RESP : state;
                RESP: state <= NO;
            endcase
        end
    end

    always_comb begin
        unique case (state)
            NO: begin
                mm_o.data = ex_i.alu_result;
            end
            REQ: begin
                if (ex_i.is_ld) begin
                    mm_o.read_req.valid = 1;
                    mm_o.read_req.addr  = ex_i.alu_result;
                end else begin
                    mm_o.write_req.valid = 1;
                    mm_o.write_req.addr  = ex_i.alu_result;
                    mm_o.write_req.data  = ex_i.data_rs2;
                end
            end
            RESP: begin
                if (ex_i.is_ld) begin
                    mm_o.data = mm_o.read_resp.data;
                end
            end
        endcase
    end

endmodule
