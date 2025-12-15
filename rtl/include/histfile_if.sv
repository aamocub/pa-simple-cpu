`ifndef HISTFILE_IF_SV
`define HISTFILE_IF_SV

interface histfile_if;
    import pa_pkg::*;

    logic                           valid;
    hf_entry_t                      entry;
    logic      [$clog2(HF_LEN)-1:0] position;

    modport HF(input valid, entry, output position);
    modport ID(output valid, entry, input position);
endinterface  // histfile_if

`endif  // HISTFILE_IF_SV
