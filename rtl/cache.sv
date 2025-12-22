// - Directly mapped
// - Write-back
// - Write-allocate

module cache
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter integer unsigned LINE_SIZE = CACHE_LINE_SIZE,
    localparam N = (LINE_SIZE / 8),
    localparam M = $clog2(N)
) (
    input logic clk_i,
    input logic rst_i,
    cache_intf stage_io,
    arbitrer_intf mem_io
);

    typedef enum {
        IDLE,
        MISS
    } state_t;
    typedef struct packed {
        logic valid;
        logic dirty;
        logic [PHY_ADDR_LEN-$clog2(LINE_SIZE):0] tag;
        logic [LINE_SIZE-1:0] data;
    } line_t;

    state_t state;
    line_t line[4];
    logic is_req_valid;
    logic is_req_in_cache;
    logic [XLEN-1:0] word;
    logic [(XLEN/2)-1:0] half;
    logic [(XLEN/4)-1:0] bite;

    // verilog_format: off
    alias tag = stage_io.req.addr[PHY_ADDR_LEN-1:N]; 
    alias idx = stage_io.req.addr[N-1:M];
    alias offset = stage_io.req.addr[M-1:0];
    // verilog_format: on

    assign is_req_valid = stage_io.req.valid;
    assign is_req_in_cache = stage_io.req.valid && line[idx].valid && tag == line[idx].tag;
    assign word = line[idx].data[offset*8+:32];
    assign half = line[idx].data[offset*8+:16];
    assign bite = line[idx].data[offset*8+:8];

    always_ff @(posedge clk_i, posedge rst_i) begin : transitions
        if (rst_i) begin
            foreach (line[i]) line[i] <= '0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    state <= is_req_valid && !is_req_in_cache ? MISS : state;
                end
                MISS: begin
                end
                default: ;
            endcase
        end
    end

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin

        end else begin
            stage_io.resp <= '0;
            case (state)
                IDLE: begin
                    if (is_req_valid && is_req_in_cache) begin
                        stage_io.resp.valid <= 1;
                        case (stage_io.req.kind)
                            READ: begin
                                case (stage_io.req.width)
                                    WORD: stage_io.resp.data <= word;
                                    HALF, UHALF: stage_io.resp.data <= half;
                                    BYTE, UBYTE: stage_io.resp.data <= bite;
                                endcase
                            end
                            WRITE: begin
                                case (stage_io.req.width)
                                    WORD: word <= stage_io.req.data;
                                    HALF, UHALF: half <= stage_io.req.data[(XLEN/2)-1:0];
                                    BYTE, UBYTE: bite <= stage_io.req.data[(XLEN/4)-1:0];
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
