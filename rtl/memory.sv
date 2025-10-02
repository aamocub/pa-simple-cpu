// Memory module

// It is assumed that all acceses are going to be of 32-bit words. In case of wanting to allow different sizes, like
// byte and half acceses, well...

module memory #(
    parameter integer NUMWORDS  = 4096,
    parameter integer DATAWIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    // reading port
    input  wire                        re_i,     // read enable
    output wire [       DATAWIDTH-1:0] rdata_o,  // read data
    input  wire [$clog2(NUMWORDS)-1:0] raddr_i,  // read address

    // writing port
    input wire                        we_i,     // write enable
    input wire [       DATAWIDTH-1:0] wdata_i,  // write data
    input wire [$clog2(NUMWORDS)-1:0] waddr_i   // write address
);

    reg [DATAWIDTH-1:0] mem[NUMWORDS];  // memory

    integer i;  // iterator for 'for loop'

    // Read combinatinoal logic (same in both ports, so explained for port A, but it applies for both)
    //
    // if reading and writing to/from the same register: rdata_a_o would be assigned wdata_i
    // else: rdata_a_o would be mem[raddr_a_i]
    assign rdata_o = (re_i & we_i & raddr_i == waddr_i) ? wdata_i : (re_i) ? mem[raddr_i] : 0;

    // Write sequential logic
    always @(posedge clk_i or posedge rst_i) begin
        // reset all registers to value 0
        if (rst_i) begin
            for (i = 0; i < NUMWORDS; i = i + 1) begin
                mem[i] <= 32'b0;
            end
        end else begin
            // if write enable, write data to mem[waddr_i] register
            if (we_i) begin
                mem[waddr_i] <= wdata_i;
            end
        end
    end

endmodule
