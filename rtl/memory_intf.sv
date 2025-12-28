// Memory interface

interface memory_intf
    import riscv_pkg::*;
    import pa_pkg::*;
#(
    parameter integer unsigned ADDR_WIDTH = PHY_ADDR_LEN,
    parameter integer unsigned DATA_WIDTH = XLEN
);

    /* --------------------------------- Request -------------------------------- */
    logic                        req_write_en;  // Write - 1 | Read - 0
    logic                        req_valid;  // Valid bit
    logic       [ADDR_WIDTH-1:0] req_addr;  // Address
    mem_width_t                  req_type;  // Type of access: {u}byte, {u}half or word
    logic       [DATA_WIDTH-1:0] req_data;  // Write data

    /* -------------------------------- Response -------------------------------- */
    logic                        resp_valid;  // Valid bit
    logic       [DATA_WIDTH-1:0] resp_data;  // Read data

    /* -------------------------------- Modports -------------------------------- */
    modport CL(
        input resp_valid, resp_data,
        output req_write_en, req_valid, req_addr, req_type, req_data
    );
    modport SV(
        input req_write_en, req_valid, req_addr, req_type, req_data,
        output resp_valid, resp_data
    );

endinterface
