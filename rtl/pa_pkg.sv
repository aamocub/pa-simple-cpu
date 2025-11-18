// This package includes all parameters, types, enums and others that are required by the processor itself.

package pa_pkg;
    import riscv_pkg::*;


    /* Memory parameters*/
    localparam MEM_ACCESS_DELAY = 1;  // How many cycles does it take the memory to access data

    /* Core definitions */

    localparam PHY_ADDR_LEN = 32;  // Bit width of physical address
    // localparam PC_RESET_ADDR = 32'h1000;
    localparam PC_RESET_ADDR = 32'h0000;
    localparam PC_EXCEPTION_ADDR = 32'h8000;
    localparam RF_NUMREGS = 32;

    // verilog_format: off
    typedef enum {
        NOP, LUI, AUIPC, JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU, LB, LH, LW, LBU, LHU, SB, SH, SW, ADDI, SLTI, SLTIU,
        XORI, ORI, ANDI, SLLI, SRLI, SRAI, ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND, ECALL, EBREAK, MUL, MULH,
        MULHSU, MULHU, DIV, DIVU, REM, REMU, ILLEGAL
    } instr_op_t;
    // verilog_format: on


    /* Control unit types */

    typedef struct packed {
        logic taken;
        logic [PHY_ADDR_LEN-1:0] addr;
        logic stall;
        logic flush;
    } cu_if_t;
    typedef struct packed {
        logic stall;
        logic flush;
    } cu_id_t;
    typedef struct packed {
        logic stall;
        logic flush;
    } cu_ex_t;
    typedef struct packed {
        logic stall;
        logic flush;
    } cu_mm_t;
    typedef struct packed {
        logic stall;
        logic flush;
    } cu_wb_t;

    /* Module types */

    typedef struct packed {
        instruction_t    instr;  // Instruction
        logic [XLEN-1:0] pc;     // Current PC
    } if_stage_t;

    typedef struct packed {
        logic [4:0]      rs1;       // Source register 1
        logic [4:0]      rs2;       // Source register 2
        logic [XLEN-1:0] data_rs1;  // Value of register 1
        logic [XLEN-1:0] data_rs2;  // Value of register 2
        logic [4:0]      rd;        // Destination register
        logic            is_wb;     // Is it going to write to regfile
        logic            is_ld;     // Is it a load
        logic            is_st;     // Is it a store
        logic            is_br;     // Is it a jump/branch
        logic            uses_rs2;  // Does the instruction use rs2
        logic [XLEN-1:0] imm;       // Immediate
        logic [XLEN-1:0] pc;        // Current PC
        instr_op_t       op;        // Operation to perform
    } id_stage_t;

    typedef struct packed {
        logic [XLEN-1:0] alu_result;
        logic            is_taken;    // Is branch taken
        logic            is_wb;       // Is it going to write to regfile
        logic            is_ld;       // Is it a load
        logic            is_st;       // Is it a store
        logic            uses_rs2;    // Does the instruction use rs2
        logic [XLEN-1:0] data_rs2;    // Value of register 2
        logic [4:0]      rd;          // Destination register
        logic            do_stall;    // Should previous instr be stalled
    } ex_stage_t;

    /* Memory arbitrer */
    typedef struct packed {
        logic                    valid;
        logic [PHY_ADDR_LEN-1:0] addr;
    } if_req_t;
    typedef struct packed {
        logic            valid;
        logic [XLEN-1:0] data;
    } if_resp_t;
    typedef struct packed {
        logic                    valid;
        logic [PHY_ADDR_LEN-1:0] addr;
    } mm_read_req_t;
    typedef struct packed {
        logic            valid;
        logic [XLEN-1:0] data;
    } mm_read_resp_t;
    typedef struct packed {
        logic                    valid;
        logic [PHY_ADDR_LEN-1:0] addr;
        logic [XLEN-1:0]         data;
    } mm_write_req_t;
    typedef struct packed {logic valid;} mm_write_resp_t;

    typedef struct packed {
        logic [XLEN-1:0] data;
        logic [XLEN-1:0] data_rs2;    // Value of register 2
        logic            is_wb;       // Is it going to write to regfile
        logic            do_stall;    // Should previous instr be stalled
        logic [4:0]      rd;          // Destination register
        mm_read_req_t    read_req;
        mm_read_resp_t   read_resp;
        mm_write_req_t   write_req;
        mm_write_resp_t  write_resp;
    } mm_stage_t;

    typedef struct packed {
        logic            is_wb;
        logic [4:0]      rd;
        logic [XLEN-1:0] data;
    } wb_stage_t;  // from WB to ID stage

    // Memory and Memory Arbitrer structs
    typedef logic [3:0] access_t;
    typedef struct packed {
        logic                    valid;
        logic [PHY_ADDR_LEN-1:0] addr;
        access_t                 byte_en;
    } mem_read_req_t;
    typedef struct packed {
        logic            valid;
        logic [XLEN-1:0] data;
    } mem_read_resp_t;
    typedef struct packed {
        logic                    valid;
        logic [PHY_ADDR_LEN-1:0] addr;
        logic [XLEN-1:0]         data;
        access_t                 byte_en;
    } mem_write_req_t;
    typedef struct packed {logic valid;} mem_write_resp_t;

endpackage
