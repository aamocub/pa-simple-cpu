`ifndef HF_COMMIT_IF_SV
`define HF_COMMIT_IF_SV

interface hf_commit_if;
    import pa_pkg::*;

    logic      valid;
    hf_entry_t entry;

    modport HF(output valid, entry);
    modport RF(input valid, entry);
endinterface  // hf_commit_if

`endif
