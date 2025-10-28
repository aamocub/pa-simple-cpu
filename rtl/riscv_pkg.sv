// This package includes all parameters, types, enums and others that are required by risc-v.

package riscv_pkg;

    localparam XLEN = 32;  // Data size of registers

    // OpCodes list
    localparam OPCODE_OP = 7'b0110011;
    localparam OPCODE_IMM = 7'b0010011;
    localparam OPCODE_LOAD = 7'b0000011;
    localparam OPCODE_STORE = 7'b0100011;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_JAL = 7'b1101111;
    localparam OPCODE_JALR = 7'b1100111;
    localparam OPCODE_LUI = 7'b0110111;
    localparam OPCODE_AUIPC = 7'b0010111;
    localparam OPCODE_ECALL = 7'b1110011;
    localparam OPCODE_EBREAK = 7'b1110011;

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
        rinstr_t rtype;
        iinstr_t itype;
        sinstr_t stype;
        uinstr_t utype;
        binstr_t btype;
        jinstr_t jtype;
    } instruction_t;

endpackage
