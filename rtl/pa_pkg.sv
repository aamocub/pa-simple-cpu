// This package includes all parameters, types, enums and others that are required by the processor itself.

package pa_pkg;

    /* Core definitions */

    localparam PHY_ADDR_LEN = 32;  // Bit width of physical address
    localparam PC_RESET_ADDR = 32'h1000;
    localparam PC_EXCEPTION_ADDR = 32'h8000;

    typedef struct packed {logic pc_sel;} ctrl_if_t;
    typedef struct packed {logic [PHY_ADDR_LEN-1:0] pc;} if_stage_t;

endpackage
