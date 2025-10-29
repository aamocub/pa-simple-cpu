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
    input  logic [DATAWIDTH-1:0] write_data_i   // write data
);

    logic [DATAWIDTH-1:0][ADDR_SIZE-1:0] mem;  // memory array to store and read memory values
    logic [$clog2(MEM_ACCESS_DELAY)-1:0] delay_cnt;  // delay counter register

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            delay_cnt <= 0;
            for (int i = 0; i < NUMWORDS; ++i) mem[i] <= '0;
        end else begin
        end
    end

endmodule
