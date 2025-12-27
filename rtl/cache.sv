// - Directly mapped
// - Write-back
// - Write-allocate

module cache
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter integer unsigned LINE_LEN = CACHE_LINE_LEN,
    localparam NUM_SETS = 4,
    localparam M = $clog2(LINE_LEN / 8),
    localparam N = $clog2(NUM_SETS) + M
) (
    input logic clk_i,
    input logic rst_i,
    cache_intf stage_io,
    memory_intf arb_io
);

    typedef enum {
        IDLE,
        MISS
    } state_t;
    typedef struct packed {
        logic valid;
        logic dirty;
        logic [PHY_ADDR_LEN-N-1:0] tag;
        logic [LINE_LEN-1:0] data;
    } line_t;

    state_t state;
    line_t line[NUM_SETS];
    logic is_req_in_cache;

    wire [PHY_ADDR_LEN-N-1:0] tag;
    wire [N-M-1:0] idx;
    wire [M*8-1:0] offset;
    assign tag = stage_io.req.addr[PHY_ADDR_LEN-1:N];
    assign idx = stage_io.req.addr[N-1:M];
    assign offset = stage_io.req.addr[M-1:0] * 8;

    assign is_req_in_cache = stage_io.req.valid && line[idx].valid && tag == line[idx].tag;

    always_ff @(posedge clk_i, posedge rst_i) begin : transitions
        if (rst_i) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    state <= (stage_io.req.valid && !is_req_in_cache) ? MISS : state;
                end
                MISS: begin
                end
                default: ;
            endcase
        end
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            foreach (line[i]) line[i] <= '0;
        end else begin
            stage_io.resp.valid <= 0;
            case (state)
                IDLE: begin
                    if (is_req_in_cache) begin
                        stage_io.resp.valid <= 1;
                        case (stage_io.req.kind)
                            READ: begin
                                case (stage_io.req.width)
                                    WORD:        stage_io.resp.data <= line[idx].data[offset+:XLEN];
                                    HALF, UHALF: stage_io.resp.data <= line[idx].data[offset+:XLEN/2];
                                    BYTE, UBYTE: stage_io.resp.data <= line[idx].data[offset+:XLEN/4];
                                endcase
                            end
                            WRITE: begin
                                line[idx].dirty <= 1;
                                case (stage_io.req.width)
                                    WORD:        line[idx].data[offset+:XLEN] <= stage_io.req.data;
                                    HALF, UHALF: line[idx].data[offset+:XLEN/2] <= stage_io.req.data[(XLEN/2)-1:0];
                                    BYTE, UBYTE: line[idx].data[offset+:XLEN/4] <= stage_io.req.data[(XLEN/4)-1:0];
                                endcase
                            end
                        endcase
                    end
                end
                MISS: begin
                end
            endcase
        end
    end

endmodule
