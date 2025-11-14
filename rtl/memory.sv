import "DPI-C" context function int fill_memory();

module memory
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    localparam int unsigned NUMWORDS = 2 << 10
) (
    input logic clk_i,
    input logic rst_i,

    input  mem_read_req_t   read_i,
    output mem_read_resp_t  read_o,
    input  mem_write_req_t  write_i,
    output mem_write_resp_t write_o
);

    logic [XLEN-1:0] mem[NUMWORDS];  // memory array to store and read memory values
    logic [$clog2(MEM_ACCESS_DELAY)-1:0] rd_delay;  // read delay counter register
    logic [PHY_ADDR_LEN-1:0] rd_addr;  // read address register

    logic [$clog2(MEM_ACCESS_DELAY)-1:0] wr_delay;  // write delay counter register
    logic [PHY_ADDR_LEN-1:0] wr_addr;  // write address register
    logic [XLEN-1:0] wr_data;  // write data register

    always_ff @(posedge clk_i, posedge rst_i) begin
        read_o.valid  <= 0;
        write_o.valid <= 0;

        if (rst_i) begin
            rd_delay <= 0;
            wr_delay <= 0;
            // mem <= '{default: 0};
            for (int i = 0; i < 1024; i = i + 1) mem[i] <= i;
        end else begin
            if (wr_delay == MEM_ACCESS_DELAY - 1) begin
                mem[wr_addr]  <= {<<8{wr_data}};  // little endian
                write_o.valid <= 1;
                wr_delay      <= 0;
            end else if (wr_delay > 0) begin
                wr_delay <= wr_delay + 1;
            end else if (write_i.valid) begin
                wr_data  <= write_i.data;
                wr_addr  <= write_i.addr;
                wr_delay <= wr_delay + 1;
            end

            if (rd_delay == MEM_ACCESS_DELAY - 1) begin
                read_o.data  <= {<<8{mem[rd_addr]}};  // little endian
                read_o.valid <= 1;
                rd_delay     <= 0;
            end else if (rd_delay > 0) begin
                rd_delay <= rd_delay + 1;
            end else if (read_i.byte_en) begin
                rd_addr  <= read_i.addr;
                rd_delay <= rd_delay + 1;
            end
        end
    end

endmodule
