module cache_data
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter integer unsigned LINE_LEN   = CACHE_LINE_LEN,
    parameter integer unsigned NUM_SETS   = 4,
    parameter integer unsigned ADDR_WIDTH = PHY_ADDR_LEN,

    localparam integer unsigned M = $clog2(LINE_LEN / 8),
    localparam integer unsigned N = $clog2(NUM_SETS) + M
) (
    input logic clk_i,
    input logic rst_i,

    input logic [ADDR_WIDTH-1:0] addr_i,
    input logic write_i,  // write enable byte, half or word to cache
    input logic write_line_i,  // write enable line to cache
    input logic [LINE_LEN-1:0] write_data_i,  // data to be written
    input mem_width_t kind_i,  // byte, half or word access

    output logic hit_o,
    output logic dirty_o,
    output logic [ADDR_WIDTH-M-1:0] tag_o,  // Tag + index of line
    output logic [XLEN-1:0] data_o,
    output logic [LINE_LEN-1:0] line_data_o
);
    typedef struct packed {
        logic valid, dirty;
        logic [ADDR_WIDTH-N-1:0] tag;
        logic [LINE_LEN-1:0] data;
    } line_t;

    wire [ADDR_WIDTH-N-1:0] tag;
    wire [N-M-1:0] idx;
    wire [M-1:0] offset;
    line_t [NUM_SETS-1:0] lines;

    assign tag = addr_i[ADDR_WIDTH-1:N];
    assign idx = addr_i[N-1:M];
    assign offset = addr_i[M-1:0];

    assign hit_o = lines[idx].tag == tag && lines[idx].valid;
    assign dirty_o = lines[idx].dirty;
    assign tag_o = {lines[idx].tag, idx};
    assign line_data_o = lines[idx].data;

    always_comb begin
        data_o = '0;
        unique case (kind_i)
            BYTE, UBYTE: data_o = {24'b0, lines[idx].data[offset*8+:8]};
            HALF, UHALF: data_o = {16'b0, lines[idx].data[offset*8+:16]};
            WORD:        data_o = {lines[idx].data[offset*8+:32]};
        endcase
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            lines <= '0;
        end else begin
            if (write_i) begin
                lines[idx].dirty <= 1;
                lines[idx].valid <= 1;
                unique case (kind_i)
                    BYTE, UBYTE: lines[idx].data[offset*8+:8] <= write_data_i[7:0];
                    HALF, UHALF: lines[idx].data[offset*8+:16] <= write_data_i[15:0];
                    WORD: lines[idx].data[offset*8+:32] <= write_data_i[31:0];
                endcase
            end else if (write_line_i) begin
                lines[idx].valid <= 1;
                lines[idx].dirty <= 0;
                lines[idx].tag   <= tag;
                lines[idx].data  <= write_data_i;
            end
        end
    end
endmodule
