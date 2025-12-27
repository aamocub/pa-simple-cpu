// import "DPI-C" context function int fill_memory();

`define RINST(f7, rs2, rs1, f3, rd, opcode) {f7, rs2, rs1, f3, rd, opcode}
`define IINST(imm, rs1, f3, rd, opcode) {imm, rs1, f3, rd, opcode}
`define SINST(imm, rs2, rs1, f3, opcode) {imm[11:5], rs2, rs1, f3, imm[4:0], opcode}
`define BINST(imm, rs2, rs1, f3, opcode) {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], opcode}
`define LINST(imm, rs1, f3, rd, opcode) {imm, rs1, f3, rd, opcode}

/*
 * All accesses to memory are done in blocks of MEM_LINE_LEN bits (i.e., 128 bits).
 */

module memory
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    // localparam int NUMWORDS = 2 << 12,
    localparam int NUMWORDS = 64,
    localparam int DELAY_SIZE = (MEM_ACCESS_DELAY == 1) ? 1 : $clog2(MEM_ACCESS_DELAY),
    localparam int MEM_SIZE = $clog2(MEM_LINE_LEN),
    parameter DEBUG = 0
) (
    input logic clk_i,
    input logic rst_i,

    memory_intf mem_io
);
    logic [12:1] joffset = -12'd6;  // interpreted as a multiple of 2 bytes
    logic [11:0] soffset = 12'd0;  // interpreted as a multiple of 2 bytes

    logic [31:0] add = `RINST(riscv_pkg::FUNCT7_ADD, 5'd1, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd31, riscv_pkg::OPCODE_ALU);
    logic [31:0] sub = `RINST(riscv_pkg::FUNCT7_SUB, 5'd2, 5'd2, riscv_pkg::FUNCT3_SUB, 5'd30, riscv_pkg::OPCODE_ALU);
    logic [31:0] addi = `IINST(12'd5, 5'd1, riscv_pkg::FUNCT3_ADDI, 5'd31, riscv_pkg::OPCODE_IMM);
    logic [31:0] beq = `BINST(joffset, 5'd1, 5'd1, riscv_pkg::FUNCT3_BEQ, riscv_pkg::OPCODE_BRANCH);
    logic [31:0] mul = `RINST(riscv_pkg::FUNCT7_MUL, 5'd6, 5'd9, riscv_pkg::FUNCT3_MUL, 5'd31, riscv_pkg::OPCODE_ALU);
    logic [31:0] lw = `LINST(12'd0, 5'd0, riscv_pkg::FUNCT3_LW, 5'd29, riscv_pkg::OPCODE_LOAD);
    logic [31:0] sw = `SINST(soffset, 5'd28, 5'd0, riscv_pkg::FUNCT3_SW, riscv_pkg::OPCODE_STORE);
    logic [31:0] instr_list[10] = {add, mul, sub, addi, sub, lw, sw, addi, mul, mul};
    /*
    logic [31:0] add1 = `RINST(riscv_pkg::FUNCT7_ADD, 5'd2, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd1, riscv_pkg::OPCODE_ALU);
    logic [31:0] add2 = `RINST(riscv_pkg::FUNCT7_ADD, 5'd3, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd1, riscv_pkg::OPCODE_ALU);
    logic [31:0] add3 = `RINST(riscv_pkg::FUNCT7_ADD, 5'd4, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd1, riscv_pkg::OPCODE_ALU);
    logic [31:0] instr_list[5] = {add1, add2, add3, add3, add3};
    */

    logic [NUMWORDS-1:0][7:0] mem;  // memory array to store and read memory values

    logic [DELAY_SIZE-1:0] rd_delay;  // read delay counter register
    logic [PHY_ADDR_LEN-1:0] rd_addr;  // read address register

    logic [DELAY_SIZE-1:0] wr_delay;  // write delay counter register
    logic [PHY_ADDR_LEN-1:0] wr_addr;  // write address register
    logic [MEM_LINE_LEN-1:0] wr_data;  // write data register

    // Shuffle 32-bit elements in little endian
    `define SHUFFLE_LE(x) {<<32{{<<8{x}}}}

    always_ff @(posedge clk_i, posedge rst_i) begin
        mem_io.read_resp.valid  <= 0;
        mem_io.write_resp.valid <= 0;

        if (rst_i) begin
            rd_delay <= 0;
            wr_delay <= 0;
            if (!DEBUG) begin
                mem <= '{default: 0};
            end
        end else begin
            if (wr_delay == MEM_ACCESS_DELAY) begin  // TODO: colocar MEM_ACCESS_DELAY-1 de nuevo
                mem[wr_addr+:MEM_LINE_LEN/8] <= `SHUFFLE_LE(wr_data);
                mem_io.write_resp.valid      <= 1;
                wr_delay                     <= 0;
            end else if (wr_delay > 0) begin
                wr_delay <= wr_delay + 1;
            end else if (mem_io.write_req.valid) begin
                wr_data  <= mem_io.write_req.data;
                wr_addr  <= mem_io.write_req.addr;
                wr_delay <= wr_delay + 1;
            end

            if (mem_io.read_req.valid) begin  // TODO: reemplazar esta versión sin MEM_ACCESS_DELAY por la de abajo
                mem_io.read_resp.data  <= `SHUFFLE_LE(mem[mem_io.read_req.addr+:MEM_LINE_LEN/8]);
                mem_io.read_resp.valid <= 1;
            end

            // if (rd_delay == MEM_ACCESS_DELAY - 1) begin
            //     // read_o.data  <= {<<8{mem[rd_addr]}};  // little endian
            //     read_o.data  <= {mem[rd_addr+3], mem[rd_addr+2], mem[rd_addr+1], mem[rd_addr+0]};  // big endian
            //     read_o.valid <= 1;
            //     rd_delay     <= 0;
            // end else if (rd_delay > 0) begin
            //     rd_delay <= rd_delay + 1;
            // end else if (read_i.valid) begin
            //     rd_addr  <= read_i.addr;
            //     rd_delay <= rd_delay + 1;
            // end
        end
    end

    initial begin
        if (DEBUG) begin
            for (int j = 0; j < NUMWORDS / 4; j = j + 1) begin
                mem[4*j+:4] = j;
            end
            for (int i = 0; i < $size(instr_list); i = i + 1) begin
                mem[PC_RESET_ADDR+4*i+:4] = instr_list[i];
            end
        end
    end
endmodule
