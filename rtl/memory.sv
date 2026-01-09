/**
* All accesses to memory are done in blocks of MEM_LINE_LEN bits (i.e., 128 bits).
*/

module memory
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    // localparam int NUMWORDS = 2 << 12,
    parameter integer unsigned NUMWORDS = 4096,
    localparam integer unsigned DELAY = MEM_ACCESS_DELAY,
    localparam integer unsigned MEM_LINE_B = MEM_LINE_LEN / 8
) (
    input logic clk_i,
    input logic rst_i,
    memory_intf.SV mem_a_io,
    memory_intf.SV mem_b_io
);
    logic [NUMWORDS-1:0][7:0] mem;  // memory array to store and read memory values

    wire a_valid, b_valid;
    wire a_wren, b_wren;
    wire [PHY_ADDR_LEN-1:0] a_addr, b_addr;
    wire [MEM_LINE_LEN-1:0] a_data, b_data;

    pipeline #(
        .CYCLES(DELAY),
        .data_t(logic [$size({a_valid, a_wren, a_addr, a_data})-1:0])
    ) port_a_pipeline (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .d_i  ({mem_a_io.req_valid, mem_a_io.req_write_en, mem_a_io.req_addr, mem_a_io.req_data}),
        .q_o  ({a_valid, a_wren, a_addr, a_data})
    );
    pipeline #(
        .CYCLES(DELAY),
        .data_t(logic [$size({b_valid, b_wren, b_addr, b_data})-1:0])
    ) port_b_pipeline (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .d_i  ({mem_b_io.req_valid, mem_b_io.req_write_en, mem_b_io.req_addr, mem_b_io.req_data}),
        .q_o  ({b_valid, b_wren, b_addr, b_data})
    );

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            // mem <= '0;
        end else begin
            mem_a_io.resp_valid <= '0;
            if (a_valid && a_wren) begin
                mem[a_addr+:MEM_LINE_B] <= {>>{a_data}};
            end else if (a_valid) begin
                mem_a_io.resp_data  <= {>>{mem[a_addr+:MEM_LINE_B]}};
                mem_a_io.resp_valid <= 1;
            end
        end
    end
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
        end else begin
            mem_b_io.resp_valid <= '0;
            if (b_valid && b_wren) begin
                mem[b_addr+:MEM_LINE_B] <= {>>{b_data}};
            end else if (b_valid) begin
                mem_b_io.resp_data  <= {>>{mem[b_addr+:MEM_LINE_B]}};
                mem_b_io.resp_valid <= 1;
            end
        end
    end

endmodule
