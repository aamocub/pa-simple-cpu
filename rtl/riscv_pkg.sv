// This package includes all parameters, types, enums and others that are required by risc-v.

package riscv_pkg;
    // verilog_format: off

    localparam XLEN = 32;  // Data size of registers

    // OpCodes list
    localparam OPCODE_ALU    = 7'b0110011;
    localparam OPCODE_IMM    = 7'b0010011;
    localparam OPCODE_LOAD   = 7'b0000011;
    localparam OPCODE_STORE  = 7'b0100011;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_JAL    = 7'b1101111;
    localparam OPCODE_JALR   = 7'b1100111;
    localparam OPCODE_LUI    = 7'b0110111;
    localparam OPCODE_AUIPC  = 7'b0010111;
    localparam OPCODE_ECALL  = 7'b1110011;
    localparam OPCODE_EBREAK = 7'b1110011;

    // Funct3 codes list
    localparam FUNCT3_JALR   = 3'b000;
    localparam FUNCT3_BEQ    = 3'b000;
    localparam FUNCT3_BNE    = 3'b001;
    localparam FUNCT3_BLT    = 3'b100;
    localparam FUNCT3_BGE    = 3'b101;
    localparam FUNCT3_BLTU   = 3'b110;
    localparam FUNCT3_BGEU   = 3'b111;
    localparam FUNCT3_LB     = 3'b000;
    localparam FUNCT3_LH     = 3'b001;
    localparam FUNCT3_LW     = 3'b010;
    localparam FUNCT3_LBU    = 3'b100;
    localparam FUNCT3_LHU    = 3'b101;
    localparam FUNCT3_SB     = 3'b000;
    localparam FUNCT3_SH     = 3'b001;
    localparam FUNCT3_SW     = 3'b010;
    localparam FUNCT3_ADDI   = 3'b000;
    localparam FUNCT3_SLTI   = 3'b010;
    localparam FUNCT3_SLTIU  = 3'b011;
    localparam FUNCT3_XORI   = 3'b100;
    localparam FUNCT3_ORI    = 3'b110;
    localparam FUNCT3_ANDI   = 3'b111;
    localparam FUNCT3_SLLI   = 3'b001;
    localparam FUNCT3_SRLI   = 3'b101;
    localparam FUNCT3_SRAI   = 3'b101;
    localparam FUNCT3_ADD    = 3'b000;
    localparam FUNCT3_SUB    = 3'b000;
    localparam FUNCT3_SLL    = 3'b001;
    localparam FUNCT3_SLT    = 3'b010;
    localparam FUNCT3_SLTU   = 3'b011;
    localparam FUNCT3_XOR    = 3'b100;
    localparam FUNCT3_SRL    = 3'b101;
    localparam FUNCT3_SRA    = 3'b101;
    localparam FUNCT3_OR     = 3'b110;
    localparam FUNCT3_AND    = 3'b111;
    localparam FUNCT3_ECALL  = 3'b000;
    localparam FUNCT3_EBREAK = 3'b000;
    localparam FUNCT3_MUL    = 3'b000;
    localparam FUNCT3_MULH   = 3'b001;
    localparam FUNCT3_MULHSU = 3'b010;
    localparam FUNCT3_MULHU  = 3'b011;
    localparam FUNCT3_DIV    = 3'b100;
    localparam FUNCT3_DIVU   = 3'b101;
    localparam FUNCT3_REM    = 3'b110;
    localparam FUNCT3_REMU   = 3'b111;

    // Funct7 codes list
    localparam FUNCT7_SLLI   = 7'b0000000;
    localparam FUNCT7_SRLI   = 7'b0000000;
    localparam FUNCT7_SRAI   = 7'b0100000;
    localparam FUNCT7_ADD    = 7'b0000000;
    localparam FUNCT7_SUB    = 7'b0100000;
    localparam FUNCT7_SLL    = 7'b0000000;
    localparam FUNCT7_SLT    = 7'b0000000;
    localparam FUNCT7_SLTU   = 7'b0000000;
    localparam FUNCT7_XOR    = 7'b0000000;
    localparam FUNCT7_SRL    = 7'b0000000;
    localparam FUNCT7_SRA    = 7'b0100000;
    localparam FUNCT7_OR     = 7'b0000000;
    localparam FUNCT7_AND    = 7'b0000000;
    localparam FUNCT7_MUL    = 7'b0000001;
    localparam FUNCT7_MULH   = 7'b0000001;
    localparam FUNCT7_MULHSU = 7'b0000001;
    localparam FUNCT7_MULHU  = 7'b0000001;
    localparam FUNCT7_DIV    = 7'b0000001;
    localparam FUNCT7_DIVU   = 7'b0000001;
    localparam FUNCT7_REM    = 7'b0000001;
    localparam FUNCT7_REMU   = 7'b0000001;

    // verilog_format: on

    // Instruction Types
    typedef struct packed {
        logic [31:25] funct7;
        logic [24:20] rs2;
        logic [19:15] rs1;
        logic [14:12] funct3;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } rinstr_t;
    typedef struct packed {
        logic [31:20] imm;
        logic [19:15] rs1;
        logic [14:12] func3;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } iinstr_t;
    typedef struct packed {
        logic [31:25] imm_1;
        logic [24:20] rs2;
        logic [19:15] rs1;
        logic [14:12] funct3;
        logic [11:7]  imm_2;
        logic [6:0]   opcode;
    } sinstr_t;
    typedef struct packed {
        logic [31:12] imm;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } uinstr_t;
    typedef struct packed {
        logic [31:31] imm_1;
        logic [30:25] imm_3;
        logic [24:20] rs2;
        logic [19:15] rs1;
        logic [14:12] funct3;
        logic [11:8]  imm_4;
        logic [7:7]   imm_2;
        logic [6:0]   opcode;
    } binstr_t;
    typedef struct packed {
        logic [31:31] imm_1;
        logic [30:21] imm_4;
        logic [20:20] imm_3;
        logic [19:12] imm_2;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } jinstr_t;
    typedef union packed {
        logic [31:0] raw;
        rinstr_t     rtype;
        iinstr_t     itype;
        sinstr_t     stype;
        uinstr_t     utype;
        binstr_t     btype;
        jinstr_t     jtype;
    } instruction_t;

endpackage
