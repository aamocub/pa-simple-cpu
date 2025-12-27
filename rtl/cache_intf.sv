// CPU-Cache interface

interface cache_intf;
    import riscv_pkg::*;
    import pa_pkg::*;

    cc_req_t  req;
    cc_resp_t resp;

    modport CL(input resp, output req);
    modport SV(output resp, input req);

endinterface
