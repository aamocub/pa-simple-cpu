package pa_pkg;
    import riscv_pkg::*;

    /* ------------------------------- Exceptions ------------------------------- */
    localparam integer unsigned PC_EXCEPTION_ADDR = 32'h8000;
    typedef struct packed {
        logic ill_instr;
        logic div_by_zero;
    } exception_t;

    /* ---------------------------- Memory parameters --------------------------- */
    // How many cycles does it take the memory to access data
    localparam integer unsigned MEM_ACCESS_DELAY = 2;
    // Bit width of physical address
    localparam integer unsigned PHY_ADDR_LEN = 32;
    // Memory line of 128 bits
    localparam integer unsigned MEM_LINE_LEN = 128;

    /* ----------------------------- Core parameters ---------------------------- */
    // PC reset address
    localparam integer unsigned PC_RESET_ADDR = 32'h0000;
    // Number of registers in regfile
    localparam integer unsigned RF_NUMREGS = 32;

    /* ---------------------------- Core definitions ---------------------------- */

    /* ------------------------- History file definitions ----------------------- */
    localparam integer unsigned HISTFILE_DEPTH = 10;
    typedef struct packed {
        logic                    valid;
        logic                    ready;
        exception_t              evec;
        logic [PHY_ADDR_LEN-1:0] pc;
        logic [PHY_ADDR_LEN-1:0] miss;
        logic [XLEN-1:0]         rd;
        logic [XLEN-1:0]         value;
    } hf_entry_t;

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

    /* ------------------------ Control unit definitions ------------------------ */
    // Control signals to IF stage
    typedef struct packed {
        logic [1:0]              pcsel;         // PC select
        logic [PHY_ADDR_LEN-1:0] addr;          // Address to jump to
        logic                    stall;         // Stall stage
        logic                    flush;         // Flush stage
        logic                    except_valid;  // Is there a valid exception
        logic [PHY_ADDR_LEN-1:0] except_addr;   // Where to jump for the exception
    } cu_if_t;
    // Control signals to ID stage
    typedef struct packed {
        logic            stall;  // Stall stage
        logic            flush;  // Flush stage
        // Exception PC register
        logic [XLEN-1:0] epc;    // PC that raised the exception
        logic            ewe;    // Write enable
    } cu_id_t;
    // Control signals to EX stage
    typedef struct packed {
        logic       stall;          // Stall stage
        logic       flush;          // Flush stage
        logic [1:0] alu_mux_a_sel;  // ALU reg A mux select
        logic [1:0] alu_mux_b_sel;  // ALU reg B Mux select
        logic [1:0] cmp_mux_a_sel;  // CMP reg A Mux select
        logic [1:0] cmp_mux_b_sel;  // CMP reg B Mux select
    } cu_ex_t;
    // Control signals to MM stage
    typedef struct packed {
        logic stall;  // Stall stage
        logic flush;  // Flush stage
    } cu_mm_t;
    // Control signals to WB stage
    typedef struct packed {
        logic stall;  // Stall stage
        logic flush;  // Flush stage
    } cu_wb_t;

    /* ---------------------------- Stage definitions --------------------------- */
    // IF stage output
    typedef struct packed {
        instruction_t    instr;  // Instruction
        logic [XLEN-1:0] pc;     // Current PC
        exception_t      evec;   // Exception vector
        logic            valid;
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
        logic [4:0]                        rs1;        // Source register 1
        logic [4:0]                        rs2;        // Source register 2
        logic [4:0]                        rd;         // Destination register
        logic [XLEN-1:0]                   data_rs1;   // Value of register 1
        logic [XLEN-1:0]                   data_rs2;   // Value of register 2
        logic [XLEN-1:0]                   data_rd;    // Value of destination register
        logic                              is_wb;      // Is it going to write to regfile
        logic                              is_ld;      // Is it a load
        logic                              is_st;      // Is it a store
        logic                              is_br;      // Is it a jump/branch
        logic                              uses_rs2;   // Does the instruction use rs2
        logic [XLEN-1:0]                   imm;        // Immediate
        logic [XLEN-1:0]                   pc;         // Current PC
        mem_width_t                        mem_width;  // Width of memory access
        instr_op_t                         op;         // Operation to perform
        exception_t                        evec;       // Exception vector
        logic [$clog2(HISTFILE_DEPTH)-1:0] hf_id;      // History file entry id
        logic                              valid;      // Is Instruction valid
    } id_stage_t;

    // EX stage output
    typedef struct packed {
        logic [4:0]                        rs1;         // Source register 1
        logic [4:0]                        rs2;         // Source register 2
        logic [4:0]                        rd;          // Destination register
        logic                              is_wb;       // Is it going to write to regfile
        logic [XLEN-1:0]                   alu_result;
        logic                              is_taken;    // Is branch taken
        logic                              is_ld;       // Is it a load
        logic                              is_st;       // Is it a store
        logic [XLEN-1:0]                   pc;          // Current PC
        logic                              uses_rs2;    // Does the instruction use rs2
        logic [XLEN-1:0]                   data_rs2;    // Value of register 2
        mem_width_t                        mem_width;   // Width of memory access
        logic                              do_stall;    // Should previous instr be stalled
        exception_t                        evec;        // Exception vector
        logic [$clog2(HISTFILE_DEPTH)-1:0] hf_id;       // History file entry id
        logic                              valid;       // Is Instruction valid
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
        logic [XLEN-1:0]                   data;
        logic [XLEN-1:0]                   data_rs2;  // Value of register 2
        logic [XLEN-1:0]                   pc;        // Current PC
        logic                              is_wb;     // Is it going to write to regfile
        logic                              do_stall;  // Should previous instr be stalled
        logic [4:0]                        rs1;       // Source register 1
        logic [4:0]                        rs2;       // Source register 2
        logic [4:0]                        rd;        // Destination register
        exception_t                        evec;      // Exception vector
        logic [$clog2(HISTFILE_DEPTH)-1:0] hf_id;     // History file entry id
        logic                              valid;     // Is Instruction valid
    } mm_stage_t;

    // WB stage output
    typedef struct packed {
        logic                              is_wb;
        logic [XLEN-1:0]                   pc;     // Current PC
        logic [4:0]                        rd;
        logic [XLEN-1:0]                   data;
        exception_t                        evec;   // Exception vector
        logic [$clog2(HISTFILE_DEPTH)-1:0] hf_id;  // History file entry id
        logic                              valid;  // Is Instruction valid
    } wb_stage_t;  // from WB to ID stage

endpackage
