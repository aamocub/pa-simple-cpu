// TODO: El dato que recibe arbitrer de memoria no se pasa directamente a IF o MM,
// sino que tarda un ciclo de más. Hay que mover la logica fuera del `always_ff` y
// hacerla combinacional

// TODO: Hay que implementar un sistema de prioridad que permita servir a la etapa MM
// porque, si no, la etapa IF acapara todos los accesos

module mem_arbitrer
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input logic clk_i,
    input logic rst_i,

    // To/From CORE -->
    input  if_req_t        if_req_i,
    output if_resp_t       if_resp_o,
    input  mm_read_req_t   mm_read_req_i,
    output mm_read_resp_t  mm_read_resp_o,
    input  mm_write_req_t  mm_write_req_i,
    output mm_write_resp_t mm_write_resp_o,

    // To/From MEMORY -->
    output mem_write_req_t  mem_write_req_o,
    input  mem_write_resp_t mem_write_resp_i,
    output mem_read_req_t   mem_read_req_o,
    input  mem_read_resp_t  mem_read_resp_i
);

    logic if_busy;
    logic mm_busy;

    always_ff @(posedge clk_i, posedge rst_i) begin
        if_busy <= 0;
        mm_busy <= 0;

        if (if_req_i.valid && !mm_busy) begin
            mem_read_req_o.valid   <= 1;
            mem_read_req_o.addr    <= if_req_i.addr;
            mem_read_req_o.byte_en <= 15;
            if_busy                <= !mem_read_resp_i.valid;
            if_resp_o.valid        <= mem_read_resp_i.valid;
            if_resp_o.data         <= mem_read_resp_i.data;
        end else if (mm_read_req_i.valid && !if_busy) begin
            mem_read_req_o.valid <= 1;
            mem_read_req_o.addr  <= mm_read_req_i.addr;
            mm_busy              <= !mem_read_resp_i.valid;
            mm_read_resp_o.valid <= mem_read_resp_i.valid;
            mm_read_resp_o.data  <= mem_read_resp_i.data;
        end

        if (mm_write_req_i.valid) begin
            mem_write_req_o.valid <= 1;
            mem_write_req_o.addr  <= mm_write_req_i.addr;
            mem_write_req_o.data  <= mm_write_req_i.data;
            mm_write_resp_o.valid <= mem_write_resp_i.valid;
        end
    end

endmodule
