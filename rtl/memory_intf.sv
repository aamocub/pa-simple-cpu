// Memory interface

interface memory_intf;
    import riscv_pkg::*;
    import pa_pkg::*;

    mem_read_req_t   read_req;
    mem_read_resp_t  read_resp;

    mem_write_req_t  write_req;
    mem_write_resp_t write_resp;

    modport CL(input read_resp, output read_req, input write_resp, output write_req);
    modport SV(output read_resp, input read_req, output write_resp, input write_req);

endinterface
