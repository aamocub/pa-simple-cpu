// import "DPI-C" context function int fill_memory();

`define RINST(f7, rs2, rs1, f3, rd, opcode) {f7, rs2, rs1, f3, rd, opcode}
`define IINST(imm, rs1, f3, rd, opcode) {imm, rs1, f3, rd, opcode}
`define SINST(imm, rs2, rs1, f3, opcode) {imm[11:5], rs2, rs1, f3, imm[4:0], opcode}
`define BINST(imm, rs2, rs1, f3, opcode) {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], opcode}

module memory
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    // localparam int NUMWORDS = 2 << 12,
    localparam int NUMWORDS = 32,
    localparam int DELAY_SIZE = (MEM_ACCESS_DELAY == 1) ? 1 : $clog2(MEM_ACCESS_DELAY),
    parameter DEBUG = 0
) (
    input logic clk_i,
    input logic rst_i,

    input  mem_read_req_t   read_i,
    output mem_read_resp_t  read_o,
    input  mem_write_req_t  write_i,
    output mem_write_resp_t write_o
);
    logic [12:1] joffset = -12'd6;  // interpreted as a multiple of 2 bytes

    logic [31:0] add = `RINST(riscv_pkg::FUNCT7_ADD, 5'd1, 5'd1, riscv_pkg::FUNCT3_ADD, 5'd31, riscv_pkg::OPCODE_ALU);
    logic [31:0] sub = `RINST(riscv_pkg::FUNCT7_SUB, 5'd2, 5'd2, riscv_pkg::FUNCT3_SUB, 5'd30, riscv_pkg::OPCODE_ALU);
    logic [31:0] addi = `IINST(12'd5, 5'd1, riscv_pkg::FUNCT3_ADDI, 5'd31, riscv_pkg::OPCODE_IMM);
    logic [31:0] beq = `BINST(joffset, 5'd1, 5'd1, riscv_pkg::FUNCT3_BEQ, riscv_pkg::OPCODE_BRANCH);
    logic [31:0] mul = `RINST(riscv_pkg::FUNCT7_MUL, 5'd6, 5'd9, riscv_pkg::FUNCT3_MUL, 5'd31, riscv_pkg::OPCODE_ALU);
    logic [31:0] instr_list[8] = {add, mul, sub, addi, sub, addi, mul, mul};

    logic [NUMWORDS-1:0][7:0] mem;  // memory array to store and read memory values

    logic [DELAY_SIZE-1:0] rd_delay;  // read delay counter register
    logic [PHY_ADDR_LEN-1:0] rd_addr;  // read address register

    logic [DELAY_SIZE-1:0] wr_delay;  // write delay counter register
    logic [PHY_ADDR_LEN-1:0] wr_addr;  // write address register
    logic [XLEN-1:0] wr_data;  // write data register

    always_ff @(posedge clk_i, posedge rst_i) begin
        read_o.valid  <= 0;
        write_o.valid <= 0;

        if (rst_i) begin
            rd_delay <= 0;
            wr_delay <= 0;
            if (!DEBUG) begin
                mem <= '{default: 0};
            end
        end else begin
            if (wr_delay == MEM_ACCESS_DELAY) begin  // TODO: colocar MEM_ACCESS_DELAY-1 de nuevo
                // mem[wr_addr]  <= {<<8{wr_data}};  // little endian
                mem[wr_addr]  <= wr_data;  // big endian
                write_o.valid <= 1;
                wr_delay      <= 0;
            end else if (wr_delay > 0) begin
                wr_delay <= wr_delay + 1;
            end else if (write_i.valid) begin
                wr_data  <= write_i.data;
                wr_addr  <= write_i.addr;
                wr_delay <= wr_delay + 1;
            end

            if (read_i.valid) begin  // TODO: quitar esta basura
                // rd_addr <= read_i.addr;
                read_o.data <= {
                    mem[read_i.addr+3], mem[read_i.addr+2], mem[read_i.addr+1], mem[read_i.addr+0]
                };  // big endian
                read_o.valid <= 1;
            end

            // if (rd_delay == MEM_ACCESS_DELAY - 1) begin
            //     // read_o.data  <= {<<8{mem[rd_addr]}};  // little endian
            //     read_o.data  <= {mem[rd_addr+3], mem[rd_addr+2], mem[rd_addr+1], mem[rd_addr+0]};  // big endian
            //     read_o.valid <= 1;
            //     rd_delay     <= 0;
            // end else if (rd_delay > 0) begin
            //     rd_delay <= rd_delay + 1;
            // end else if (read_i.valid) begin  // TODO: preocuparse de accesos que sean HALF, BYTE y WORD
            //     rd_addr  <= read_i.addr;
            //     rd_delay <= rd_delay + 1;
            // end
        end
    end

    initial begin
        if (DEBUG) begin
            mem = '{default: 0};
            for (int i = 0; i < $size(instr_list); i = i + 1) begin
                mem[PC_RESET_ADDR+4*i+:4] = instr_list[i];
            end
        end
    end
endmodule
