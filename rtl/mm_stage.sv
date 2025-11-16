module mm_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input logic clk_i,
    input logic rst_i,
    input ex_stage_t ex_i,
    output mm_stage_t mm_o
);


    enum {
        NO,   // Don't do anything
        REQ,  // Request to memory and wait for response
        RESP  // Response from memory
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
        mm_o.rd = ex_i.rd;
        mm_o.is_wb = ex_i.is_wb;
        unique case (state)
            NO: begin
                mm_o.data = ex_i.alu_result;
                mm_o.do_stall = 0;
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
                mm_o.do_stall = 1;
            end
            RESP: begin
                if (ex_i.is_ld) begin
                    mm_o.data = mm_o.read_resp.data;
                end
                mm_o.do_stall = 0;
            end
        endcase
    end

endmodule
