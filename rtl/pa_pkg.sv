// This package includes all parameters, types, enums and others that are required by the processor itself.

package pa_pkg;
    import riscv_pkg::*;

    /* Core definitions */

    localparam PHY_ADDR_LEN = 32;  // Bit width of physical address
    localparam PC_RESET_ADDR = 32'h1000;
    localparam PC_EXCEPTION_ADDR = 32'h8000;

    // verilog_format: off
    typedef enum {
        LUI, AUIPC, JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU, LB, LH, LW, LBU, LHU, SB, SH, SW, ADDI, SLTI, SLTIU,
        XORI, ORI, ANDI, SLLI, SRLI, SRAI, ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND, ECALL, EBREAK, MUL, MULH,
        MULHSU, MULHU, DIV, DIVU, REM, REMU
    } instr_op_t;
    // verilog_format: on

    typedef struct packed {
        logic pc_sel;
        logic stall;
    } ctrl_if_t;
    typedef struct packed {instruction_t instr;} if_stage_t;

    typedef struct packed {
        logic [4:0]  rs1;    // Source register 1
        logic [4:0]  rs2;    // Source register 2
        logic [4:0]  rd;     // Destination register
        logic        is_wb;  // Is it going to write to regfile
        logic [31:0] imm;    // Is it going to write to regfile
        instr_op_t   op;     // Operation to perform
    } id_stage_t;

    /* Memory controller */
    typedef struct packed {
        logic valid;
        logic [PHY_ADDR_LEN-1:0] addr;
    } if_req_t;
    typedef struct packed {
        logic valid;
        logic [XLEN-1:0] data;
    } if_resp_t;
    typedef struct packed {
        logic valid;
        logic [PHY_ADDR_LEN-1:0] addr;
    } m_read_req_t;
    typedef struct packed {
        logic valid;
        logic [XLEN-1:0] data;
    } m_read_resp_t;
    typedef struct packed {
        logic valid;
        logic [PHY_ADDR_LEN-1:0] addr;
        logic [XLEN-1:0] data;
    } m_write_req_t;
    typedef struct packed {logic valid;} m_write_resp_t;

endpackage
