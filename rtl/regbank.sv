// Register Bank
// It is composed of NUMREGS amount of registers that can be accessed through the reading ports (A and B)
// and writing port

module regbank #(
    parameter integer NUMREGS   = 32,
    parameter integer DATAWIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    // reading port A
    input  wire                       re_a_i,     // read A enable
    output reg  [      DATAWIDTH-1:0] rdata_a_o,  // read A data
    input  wire [$clog2(NUMREGS)-1:0] raddr_a_i,  // read A address

    // reading port B
    input  wire                       re_b_i,     // read B enable
    output reg  [      DATAWIDTH-1:0] rdata_b_o,  // read B data
    input  wire [$clog2(NUMREGS)-1:0] raddr_b_i,  // read B address

    // writing port
    input wire                       we_i,     // write enable
    input wire [      DATAWIDTH-1:0] wdata_i,  // write data
    input wire [$clog2(NUMREGS)-1:0] waddr_i   // write address
);

    reg [DATAWIDTH-1:0] bank[NUMREGS];  // register bank

    integer i;  // iterator for 'for loop'

    // Read sequential logic (same in both ports, so explained for port A, but it applies for both)
    //
    // if reading and writing to/from the same register: rdata_a_o would be assigned wdata_i
    // else: rdata_a_o would be bank[raddr_a_i]
    always_ff @(posedge clk_i or posedge rst_i) begin
        rdata_a_o <= (re_b_i & we_i & raddr_b_i == waddr_i) ? wdata_i : (re_b_i) ? bank[raddr_b_i] : 0;
        rdata_b_o <= (re_b_i & we_i & raddr_b_i == waddr_i) ? wdata_i : (re_b_i) ? bank[raddr_b_i] : 0;
        if (rst_i) begin
            rdata_a_o <= 0;
            rdata_b_o <= 0;
        end
    end

    // Write sequential logic
    always_ff @(posedge clk_i or posedge rst_i) begin
        // reset all registers to value 0
        if (rst_i) begin
            for (i = 0; i < NUMREGS; i = i + 1) begin
                // bank[i] <= 32'b0;
                bank[i] <= i;
            end
        end else begin
            // if write enable, write data to bank[waddr_i] register
            if (we_i && (waddr_i != 5'b0)) begin
                bank[waddr_i] <= wdata_i;
            end
        end
    end

endmodule
