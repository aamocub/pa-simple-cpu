`include "opcode.svh"

`define assert(op, signal, value) \
        if ((signal) != (value)) begin \
            $display("ASSERTION FAILED in %m: op(%0d) %s(%0d) != %0d", op, `"signal`", signal, value); \
            $finish; \
        end

module alu_tb ();

localparam integer DW = 32; // Data width
localparam integer CLK_PERIOD = 20;

reg clk;
reg rst;
reg [DW-1:0] a_i;
reg [DW-1:0] b_i;
reg [3:0] opcode_i;
reg [DW-1:0] out_o;

// Generate clock signal
always #(CLK_PERIOD / 2) clk = ~clk;

alu #(
        .DATAWIDTH(DW)
) alu (
        .a_i     (a_i),
        .b_i     (b_i),
        .opcode_i(opcode_i),
        .out_o   (out_o)
);

reg [3:0] i;
initial begin
        clk = 1;
        rst = 1;
        #CLK_PERIOD;

        rst = 0;
        #CLK_PERIOD;

        a_i = 32'd34;
        b_i = 32'd35;
        #CLK_PERIOD;

        for (i = 0; i < 15; i = i + 1) begin
                opcode_i = i;
                #CLK_PERIOD;

                case (opcode_i)
                        `NOP_OP: `assert(opcode_i, out_o, 32'b0)
                        `ADD_OP: `assert(opcode_i, out_o, a_i + b_i)
                        `LW_OP:  `assert(opcode_i, out_o, a_i + b_i)
                        `SW_OP:  `assert(opcode_i, out_o, a_i + b_i)
                        `SUB_OP: `assert(opcode_i, out_o, a_i - b_i)
                        `MUL_OP: `assert(opcode_i, out_o, a_i * b_i)
                        `DIV_OP: `assert(opcode_i, out_o, a_i / b_i)
                        `AND_OP: `assert(opcode_i, out_o, a_i & b_i)
                        `OR_OP:  `assert(opcode_i, out_o, a_i | b_i)
                        `XOR_OP: `assert(opcode_i, out_o, a_i ^ b_i)
                        `JMP_OP: `assert(opcode_i, out_o, a_i + b_i)
                        `BEQ_OP: `assert(opcode_i, out_o, a_i + b_i)
                        `BGT_OP: `assert(opcode_i, out_o, a_i + b_i)
                        `BGE_OP: `assert(opcode_i, out_o, a_i + b_i)
                        `ADDI_OP:  `assert(opcode_i, out_o, a_i + b_i)
                endcase
                $display("OP %0d A %0d B %0d OUT %0d", opcode_i, a_i, b_i, out_o);
                #CLK_PERIOD;
        end
        $finish();
end

endmodule
