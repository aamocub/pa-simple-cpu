interface cache_intf;
    import riscv_pkg::*;
    import pa_pkg::*;

    cc_req_t  req;
    cc_resp_t resp;

    modport STAGE(input resp, output req);
    modport CACHE(output resp, input req);
endinterface  //cache_intf
