module ex_stage
    import riscv_pkg::*;
    import pa_pkg::*;
(
    input  logic                 clk_i,
    input  logic                 rst_i,
    input  id_stage_t            id_i,
    input  cu_ex_t               cu_i,
    input  logic      [XLEN-1:0] bypass_mm_data,
    input  logic      [XLEN-1:0] bypass_wb_data,
    output ex_stage_t            ex_o
);
    logic div_by_zero;
    always_comb begin : exceptions
        ex_o.evec             = id_i.evec;
        ex_o.evec.div_by_zero = div_by_zero;
    end

    always_comb begin : passthrough_signals
        ex_o.is_wb     = id_i.is_wb;
        ex_o.is_ld     = id_i.is_ld;
        ex_o.is_st     = id_i.is_st;
        ex_o.uses_rs2  = id_i.uses_rs2;
        ex_o.rd        = id_i.rd;
        ex_o.rs1       = id_i.rs1;
        ex_o.rs2       = id_i.rs2;
        ex_o.pc        = id_i.pc;
        ex_o.mem_width = id_i.mem_width;
        ex_o.hf_id     = id_i.hf_id;
        ex_o.valid     = id_i.valid;
    end

    logic [XLEN-1:0] alu_a, alu_b;
    logic [XLEN-1:0] cmp_a, cmp_b;
    always_comb begin : mux_alu_a
        case (cu_i.alu_mux_a_sel)
            0: alu_a = id_i.op == AUIPC ? id_i.pc : id_i.data_rs1;
            1: alu_a = id_i.pc;
            2: alu_a = bypass_mm_data;
            3: alu_a = bypass_wb_data;
            default: alu_a = id_i.data_rs1;
        endcase
    end
    always_comb begin : mux_alu_b
        case (cu_i.alu_mux_b_sel)
            0: alu_b = id_i.imm;
            1: alu_b = bypass_mm_data;
            2: alu_b = bypass_wb_data;
            3: alu_b = id_i.data_rs2;
            default: alu_b = id_i.imm;
        endcase
    end
    always_comb begin : mux_cmp_a
        case (cu_i.cmp_mux_a_sel)
            0: cmp_a = id_i.data_rs1;
            1: cmp_a = bypass_mm_data;
            2: cmp_a = bypass_wb_data;
            default: cmp_a = id_i.data_rs1;
        endcase
    end
    always_comb begin : mux_cmp_b
        case (cu_i.cmp_mux_b_sel)
            0: cmp_b = id_i.data_rs2;
            1: cmp_b = bypass_mm_data;
            2: cmp_b = bypass_wb_data;
            default: cmp_b = id_i.data_rs2;
        endcase
        ex_o.data_rs2 = cmp_b;
    end

    cmp cmp (
        .a_i  (cmp_a),
        .b_i  (cmp_b),
        .op_i (id_i.op),
        .out_o(ex_o.is_taken)
    );

    alu alu (
        .clk_i     (clk_i),
        .rst_i     (rst_i),
        .a_i       (alu_a),
        .b_i       (alu_b),
        .opcode_i  (id_i.op),
        .out_o     (ex_o.alu_result),
        .stall_o   (ex_o.do_stall),
        .div_zero_o(div_by_zero)
    );

endmodule
