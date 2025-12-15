package pa_pkg;
    import riscv_pkg::*;

    /* --------------------------------------------- Memory definitions --------------------------------------------- */
    // verilog_format: off
    localparam MEM_ACCESS_DELAY = 1;  // How many cycles does it take the memory to access data
    localparam PHY_ADDR_LEN     = 32; // Bit width of physical address
    typedef enum logic [2:0] { BYTE, UBYTE, HALF, UHALF, WORD } mem_width_t; // Size/width of memory access
    // verilog_format: on

    /* ----------------------------------------- Memory arbitrer definitions ---------------------------------------- */
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


    /* ------------------------------------------------- Exceptions ------------------------------------------------- */
    localparam PC_EXCEPTION_ADDR = 32'h8000;
    typedef struct packed {
        logic ill_instr;
        logic div_by_zero;
    } exception_t;

    /* ---------------------------------------------- Core definitions ---------------------------------------------- */
    localparam PC_RESET_ADDR = 32'h0000;
    localparam RF_NUMREGS = 32;

    /* ------------------------------------------------ History File ------------------------------------------------ */
    localparam HF_LEN = 10;
    typedef struct packed {
        logic                    valid;   // Valid bit : entry is occupied
        logic                    ready;   // Ready bit : entry has the result
        logic [PHY_ADDR_LEN-1:0] addr;    // Address in case of LOAD or STORE
        logic [PHY_ADDR_LEN-1:0] pc;      // PC
        exception_t              evec;    // Exception vector
        logic [XLEN-1:0]         rd;      // Destination
        logic [XLEN-1:0]         result;  // Result
    } hf_entry_t;

    /* --------------------------------------------- Decode definitions --------------------------------------------- */
    // verilog_format: off
    typedef enum {
        NOP, LUI, AUIPC, JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU, LB, LH, LW, LBU, LHU, SB, SH, SW, ADDI, SLTI, SLTIU,
        XORI, ORI, ANDI, SLLI, SRLI, SRAI, ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND, ECALL, EBREAK, MUL, MULH,
        MULHSU, MULHU, DIV, DIVU, REM, REMU, ILLEGAL
    } instr_op_t;
    // verilog_format: on

    /* --------------------------------------------- Control definitions -------------------------------------------- */
    typedef struct packed {
        logic [1:0]              pcsel;         // PC select
        logic [PHY_ADDR_LEN-1:0] addr;          // Address to jump to
        logic                    stall;         // Stall stage
        logic                    flush;         // Flush stage
        logic                    except_valid;  // Is there a valid exception
        logic [PHY_ADDR_LEN-1:0] except_addr;   // Where to jump for the exception
    } cu_if_t;
    typedef struct packed {
        logic            stall;  // Stall stage
        logic            flush;  // Flush stage
        // Exception PC register
        logic [XLEN-1:0] epc;    // PC that raised the exception
        logic            ewe;    // Write enable
    } cu_id_t;
    typedef struct packed {
        logic       stall;          // Stall stage
        logic       flush;          // Flush stage
        logic [1:0] alu_mux_a_sel;  // ALU reg A mux select
        logic [1:0] alu_mux_b_sel;  // ALU reg B Mux select
        logic [1:0] cmp_mux_a_sel;  // CMP reg A Mux select
        logic [1:0] cmp_mux_b_sel;  // CMP reg B Mux select
    } cu_ex_t;
    typedef struct packed {
        logic stall;  // Stall stage
        logic flush;  // Flush stage
    } cu_mm_t;
    typedef struct packed {
        logic stall;  // Stall stage
        logic flush;  // Flush stage
    } cu_wb_t;

    /* ---------------------------------------------- Stage definitions --------------------------------------------- */
    typedef struct packed {
        instruction_t    instr;  // Instruction
        logic [XLEN-1:0] pc;     // Current PC
        exception_t      evec;   // Exception vector
    } if_stage_t;

    typedef struct packed {
        logic [4:0]      rs1;        // Source register 1
        logic [4:0]      rs2;        // Source register 2
        logic [4:0]      rd;         // Destination register
        logic [XLEN-1:0] data_rs1;   // Value of register 1
        logic [XLEN-1:0] data_rs2;   // Value of register 2
        logic            is_wb;      // Is it going to write to regfile
        logic            is_ld;      // Is it a load
        logic            is_st;      // Is it a store
        logic            is_br;      // Is it a jump/branch
        logic            uses_rs2;   // Does the instruction use rs2
        logic [XLEN-1:0] imm;        // Immediate
        logic [XLEN-1:0] pc;         // Current PC
        mem_width_t      mem_width;  // Width of memory access
        instr_op_t       op;         // Operation to perform
        exception_t      evec;       // Exception vector
    } id_stage_t;

    typedef struct packed {
        logic [4:0]      rs1;         // Source register 1
        logic [4:0]      rs2;         // Source register 2
        logic [4:0]      rd;          // Destination register
        logic            is_wb;       // Is it going to write to regfile
        logic [XLEN-1:0] alu_result;
        logic            is_taken;    // Is branch taken
        logic            is_ld;       // Is it a load
        logic            is_st;       // Is it a store
        logic [XLEN-1:0] pc;          // Current PC
        logic            uses_rs2;    // Does the instruction use rs2
        logic [XLEN-1:0] data_rs2;    // Value of register 2
        mem_width_t      mem_width;   // Width of memory access
        logic            do_stall;    // Should previous instr be stalled
        exception_t      evec;        // Exception vector
    } ex_stage_t;

    typedef struct packed {
        logic [XLEN-1:0] data;
        logic [XLEN-1:0] data_rs2;  // Value of register 2
        logic [XLEN-1:0] pc;        // Current PC
        logic            is_wb;     // Is it going to write to regfile
        logic            do_stall;  // Should previous instr be stalled
        logic [4:0]      rs1;       // Source register 1
        logic [4:0]      rs2;       // Source register 2
        logic [4:0]      rd;        // Destination register
        exception_t      evec;      // Exception vector
    } mm_stage_t;

    typedef struct packed {
        logic            is_wb;
        logic [XLEN-1:0] pc;     // Current PC
        logic [4:0]      rd;
        logic [XLEN-1:0] data;
        exception_t      evec;   // Exception vector
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
