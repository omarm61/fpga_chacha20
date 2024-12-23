module fifo_axis #(
    parameter integer C_FIFO_WIDTH = 32,
    parameter integer C_FIFO_DEPTH = 8
) (
    // Clock/rese
    input  wire                    i_aclk,
    input  wire                    i_aresetn,
    // AXI-Stream - INPUT
    output wire                    s_axis_tready,
    input  wire                    s_axis_tvalid,
    input  wire [C_FIFO_WIDTH-1:0] s_axis_tdata,
    //
    // AXI-Stream - OUTPUT
    input  wire                    m_axis_tready,
    output wire                    m_axis_tvalid,
    output wire [C_FIFO_WIDTH-1:0] m_axis_tdata
);


  // **Registers
  reg  [$clog2(C_FIFO_DEPTH)-1:0] r_write_ptr;
  reg  [$clog2(C_FIFO_DEPTH)-1:0] r_read_ptr;
  reg  [        C_FIFO_WIDTH-1:0] r_fifo        [C_FIFO_DEPTH];

  reg  [        C_FIFO_WIDTH-1:0] r_axis_tdata;
  reg                             r_axis_tvalid;

  // **Wires
  wire                            w_full;
  wire                            w_empty;

  // Assignments
  assign w_full = ((r_write_ptr + 1'b1) == r_read_ptr);
  assign w_empty = (r_write_ptr == r_read_ptr);

  assign s_axis_tready = !w_full;
  assign m_axis_tvalid = r_axis_tvalid;
  assign m_axis_tdata = r_axis_tdata;

  integer i;
  // Write data to FIFO
  always @(posedge i_aclk or negedge i_aresetn) begin
    if (!i_aresetn) begin
      // Reset data FIFO content
      for (i = 0; i < C_FIFO_DEPTH; i = i + 1) begin
        r_fifo[i] <= 'd0;
      end
      r_write_ptr <= 'd0;
    end else begin
      if (s_axis_tready && s_axis_tvalid && !w_full) begin
        r_fifo[r_write_ptr] <= s_axis_tdata;
        r_write_ptr <= r_write_ptr + 1'b1;
      end
    end
  end

  // Read data from FIFO
  always @(posedge i_aclk or negedge i_aresetn) begin
    if (!i_aresetn) begin
      r_read_ptr <= 'd0;
    end else begin
      if (m_axis_tready) begin
        if (!w_empty) begin
          r_axis_tdata <= r_fifo[r_read_ptr];
          r_axis_tvalid <= 1'b1;
          r_read_ptr <= r_read_ptr + 1'b1;
        end else begin
          r_axis_tvalid <= 1'b0;
        end
      end
    end
  end
endmodule
