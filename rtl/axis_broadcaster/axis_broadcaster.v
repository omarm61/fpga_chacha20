module axis_broadcaster #(
  parameter integer C_DATA_WIDTH = 32
) (
    // AXI-Stream - INPUT
    output wire                    s_axis_tready,
    input  wire                    s_axis_tvalid,
    input  wire [C_DATA_WIDTH-1:0] s_axis_tdata,
    // CH1
    input  wire                    m_axis_1_tready,
    output wire                    m_axis_1_tvalid,
    output wire [C_DATA_WIDTH-1:0] m_axis_1_tdata,
    // CH2
    input  wire                    m_axis_2_tready,
    output wire                    m_axis_2_tvalid,
    output wire [C_DATA_WIDTH-1:0] m_axis_2_tdata
);


assign s_axis_tready = m_axis_1_tready && m_axis_2_tready;

// CH1
assign m_axis_1_tdata = s_axis_tdata;
assign m_axis_1_tvalid = s_axis_tvalid;
// CH2
assign m_axis_2_tdata = s_axis_tdata;
assign m_axis_2_tvalid = s_axis_tvalid;

endmodule
