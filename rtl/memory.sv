// TODO: byte and half access

module memory #(
    parameter  NUMWORDS         = 4096,              // Number of words in the memory
    parameter  DATAWIDTH        = 32,                // Bit width of a word
    localparam ADDR_SIZE        = $clog2(NUMWORDS),
    localparam MEM_ACCESS_DELAY = 5                  // How many cycles does it take the memory to access data
) (
    input  logic                 clk_i,
    input  logic                 rst_i,
    input  logic                 read_en_i,     // read enable
    input  logic [ADDR_SIZE-1:0] read_addr_i,   // read address
    output logic                 read_valid_o,  // read valid
    output logic [DATAWIDTH-1:0] read_data_o,   // read data
    input  logic                 write_en_i,    // write enable
    input  logic [ADDR_SIZE-1:0] write_addr_i,  // write address
    input  logic [DATAWIDTH-1:0] write_data_i,  // write data
    output logic                 write_valid_o  // write valid
);

    logic [DATAWIDTH-1:0][ADDR_SIZE-1:0] mem;  // memory array to store and read memory values
    logic [$clog2(MEM_ACCESS_DELAY)-1:0] rd_delay;  // read delay counter register
    logic [ADDR_SIZE-1:0] rd_addr;  // read address register

    logic [$clog2(MEM_ACCESS_DELAY)-1:0] wr_delay;  // write delay counter register
    logic [ADDR_SIZE-1:0] wr_addr;  // write address register
    logic [DATAWIDTH-1:0] wr_data;  // write data register

    always_ff @(posedge clk_i, posedge rst_i) begin
        read_valid_o  <= 0;
        write_valid_o <= 0;

        if (rst_i) begin
            rd_delay <= 0;
            wr_delay <= 0;
            for (int i = 0; i < NUMWORDS; ++i) mem[i] <= '0;
        end else begin
            if (wr_delay == MEM_ACCESS_DELAY) begin
                mem[wr_addr]  <= wr_data;
                write_valid_o <= 1;
                wr_delay      <= 0;
            end else if (wr_delay > 0) begin
                wr_delay <= wr_delay + 1;
            end else if (write_en_i) begin
                write_addr <= write_addr_i;
                wr_delay   <= wr_delay + 1;
            end

            if (rd_delay == MEM_ACCESS_DELAY) begin
                read_data_o  <= mem[rd_addr];
                read_valid_o <= 1;
                rd_delay     <= 0;
            end else if (rd_delay > 0) begin
                rd_delay <= rd_delay + 1;
            end else if (read_en_i) begin
                rd_addr  <= read_addr_i;
                rd_delay <= rd_delay + 1;
            end
        end
    end

endmodule
