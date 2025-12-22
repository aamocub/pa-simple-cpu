// Memory arbitrer interface

interface arbitrer_intf;
    import riscv_pkg::*;
    import pa_pkg::*;

    arb_req_t  req;
    arb_resp_t resp;

    modport CACHE(input resp, output req);
    modport ARB(output resp, input req);

endinterface  //arb_intf
