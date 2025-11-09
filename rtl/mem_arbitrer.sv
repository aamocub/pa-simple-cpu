module mem_arbitrer
    import pa_pkg::*;
    import riscv_pkg::*;
(
    input logic clk_i,
    input logic rst_i,

    input  if_req_t       if_req_i,
    output if_resp_t      if_resp_o,
    input  m_read_req_t   m_read_req_i,
    output m_read_resp_t  m_read_resp_o,
    input  m_write_req_t  m_write_req_i,
    output m_write_resp_t m_write_resp_o,

    output logic                    read_en_o,
    output logic [PHY_ADDR_LEN-1:0] read_addr_o,
    input  logic                    read_valid_i,
    input  logic [        XLEN-1:0] read_data_i,
    output logic                    write_en_o,
    output logic [PHY_ADDR_LEN-1:0] write_addr_o,
    output logic [        XLEN-1:0] write_data_o,
    input  logic                    write_valid_i
);

    logic if_busy;
    logic m_busy;

    always_ff @(posedge clk_i, posedge rst_i) begin
        if_busy <= 0;
        m_busy  <= 0;

        if (if_req_i.valid && !m_busy) begin
            read_en_o       <= 1;
            read_addr_o     <= if_req_i.addr;
            if_busy         <= !read_valid_i;
            if_resp_o.valid <= read_valid_i;
            if_resp_o.data  <= read_data_i;
        end else if (m_read_req_i.valid && !if_busy) begin
            read_en_o           <= 1;
            read_addr_o         <= m_read_req_i.addr;
            m_busy              <= !read_valid_i;
            m_read_resp_o.valid <= read_valid_i;
            m_read_resp_o.data  <= read_data_i;
        end

        if (m_write_req_i.valid) begin
            write_en_o           <= 1;
            write_addr_o         <= m_write_req_i.addr;
            m_write_resp_o.valid <= write_valid_i;
            write_data_o         <= m_write_req_i.data;
        end
    end

endmodule
