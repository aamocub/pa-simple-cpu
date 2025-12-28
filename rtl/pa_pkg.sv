// This package includes all parameters, types, enums and others that are required by the processor itself.

package pa_pkg;
    import riscv_pkg::*;

    /* ---------------------------- Memory parameters --------------------------- */
    // How many cycles does it take the memory to access data
    localparam integer unsigned MEM_ACCESS_DELAY = 1;
    // Bit width of physical address
    localparam integer unsigned PHY_ADDR_LEN = 32;
    // Memory line of 128 bits
    localparam integer unsigned MEM_LINE_LEN = 128;

    /* ----------------------------- Core parameters ---------------------------- */
    // PC reset address
    localparam integer unsigned PC_RESET_ADDR = 32'h0000;
    // PC exception address
    localparam integer unsigned PC_EXCEPTION_ADDR = 32'h8000;
    // Number of registers in regfile
    localparam integer unsigned RF_NUMREGS = 32;

    /* ---------------------------- Core definitions ---------------------------- */

    /* --------------------------- Memory definitions --------------------------- */
    // Memory access width ({U}BYTE, {U}HALF, WORD)
    typedef enum logic [2:0] {
        BYTE,
        UBYTE,
        HALF,
        UHALF,
        WORD
    } mem_width_t;
    typedef struct packed {
        logic                    valid;
        logic [PHY_ADDR_LEN-1:0] addr;
    } mem_read_req_t;
    typedef struct packed {
        logic                    valid;
        logic [MEM_LINE_LEN-1:0] data;
    } mem_read_resp_t;
    typedef struct packed {
        logic                    valid;
        logic [PHY_ADDR_LEN-1:0] addr;
        logic [MEM_LINE_LEN-1:0] data;
    } mem_write_req_t;
    typedef struct packed {
        logic valid;  //
    } mem_write_resp_t;

    /* ---------------------------- Cache parameters ---------------------------- */
    // Cache line length in bits (should be set to 128)
    localparam integer unsigned CACHE_LINE_LEN = 128;

    /* ---------------------------- Cache definitions --------------------------- */
    typedef enum logic {
        READ,
        WRITE
    } access_t;
    typedef struct packed {
        access_t                 kind;
        mem_width_t              width;
        logic                    valid;
        logic [PHY_ADDR_LEN-1:0] addr;
        logic [XLEN-1:0]         data;
    } cc_req_t;
    typedef struct packed {
        logic            valid;
        logic [XLEN-1:0] data;
    } cc_resp_t;

    /* ------------------------ Control unit definitions ------------------------ */
    // Control signals to IF stage
    typedef struct packed {
        logic taken;
        logic [PHY_ADDR_LEN-1:0] addr;
        logic stall;
        logic flush;
    } cu_if_t;
    // Control signals to ID stage
    typedef struct packed {
        logic stall;
        logic flush;
    } cu_id_t;
    // Control signals to EX stage
    typedef struct packed {
        logic stall;
        logic flush;
        logic [1:0] alu_mux_a_sel;
        logic [1:0] alu_mux_b_sel;
        logic [1:0] cmp_mux_a_sel;
        logic [1:0] cmp_mux_b_sel;
    } cu_ex_t;
    // Control signals to MM stage
    typedef struct packed {
        logic stall;
        logic flush;
    } cu_mm_t;
    // Control signals to WB stage
    typedef struct packed {
        logic stall;
        logic flush;
    } cu_wb_t;

    /* ---------------------------- Stage definitions --------------------------- */
    // IF stage output
    typedef struct packed {
        instruction_t    instr;  // Instruction
        logic [XLEN-1:0] pc;     // Current PC
    } if_stage_t;

    // Instruction codes
    // verilog_format: off
    typedef enum {
        NOP,
        LUI, AUIPC, JAL, JALR,
        BEQ, BNE, BLT, BGE, BLTU, BGEU,
        LB, LH, LW, LBU, LHU, SB, SH, SW,
        ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI,
        ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
        ECALL, EBREAK,
        MUL, MULH, MULHSU, MULHU,
        DIV, DIVU, REM, REMU,
        ILLEGAL
    } instr_op_t;
    // verilog_format: on

    // ID stage ouput
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
    } id_stage_t;

    // EX stage output
    typedef struct packed {
        logic [4:0]      rs1;         // Source register 1
        logic [4:0]      rs2;         // Source register 2
        logic [4:0]      rd;          // Destination register
        logic            is_wb;       // Is it going to write to regfile
        logic [XLEN-1:0] alu_result;
        logic            is_taken;    // Is branch taken
        logic            is_ld;       // Is it a load
        logic            is_st;       // Is it a store
        logic            uses_rs2;    // Does the instruction use rs2
        logic [XLEN-1:0] data_rs2;    // Value of register 2
        mem_width_t      mem_width;   // Width of memory access
        logic            do_stall;    // Should previous instr be stalled
    } ex_stage_t;

    // MM memory interface
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

    // MM stage output
    typedef struct packed {
        logic [XLEN-1:0] data;
        logic [XLEN-1:0] data_rs2;  // Value of register 2
        logic            is_wb;     // Is it going to write to regfile
        logic            do_stall;  // Should previous instr be stalled
        logic [4:0]      rs1;       // Source register 1
        logic [4:0]      rs2;       // Source register 2
        logic [4:0]      rd;        // Destination register
    } mm_stage_t;

    // WB stage output
    typedef struct packed {
        logic            is_wb;
        logic [4:0]      rd;
        logic [XLEN-1:0] data;
    } wb_stage_t;  // from WB to ID stage

endpackage
