// This package includes all parameters, types, enums and others that are required by the processor itself.

package pa_pkg;
    import riscv_pkg::*;

    /* Core definitions */

    localparam PHY_ADDR_LEN = 32;  // Bit width of physical address
    localparam PC_RESET_ADDR = 32'h1000;
    localparam PC_EXCEPTION_ADDR = 32'h8000;

    typedef struct packed {
        logic pc_sel;
        logic stall;
    } ctrl_if_t;
    typedef struct packed {logic [XLEN-1:0] instr;} if_stage_t;

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
