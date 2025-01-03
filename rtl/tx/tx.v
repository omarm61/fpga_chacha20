module tx #(
    // Input Clock in MHz
    parameter integer C_CLOCK_FREQ = 100,
    //
    // Parameters of Axi Slave Bus Interface S_AXI
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 32

) (
    // Clock, Reset
    input  wire                                s_axi_aclk,
    input  wire                                s_axi_aresetn,
    // Ports of Axi Slave Bus Interface S_AXI
    input  wire [    C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
    input  wire [                       2 : 0] s_axi_awprot,
    input  wire                                s_axi_awvalid,
    output wire                                s_axi_awready,
    input  wire [    C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
    input  wire                                s_axi_wvalid,
    output wire                                s_axi_wready,
    output wire [                       1 : 0] s_axi_bresp,
    output wire                                s_axi_bvalid,
    input  wire                                s_axi_bready,
    input  wire [    C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
    input  wire [                       2 : 0] s_axi_arprot,
    input  wire                                s_axi_arvalid,
    output wire                                s_axi_arready,
    output wire [    C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
    output wire [                       1 : 0] s_axi_rresp,
    output wire                                s_axi_rvalid,
    input  wire                                s_axi_rready,
    // AXI-Stream - INPUT
    output wire                                s_axis_tready,
    input  wire                                s_axis_tvalid,
    input  wire [                        31:0] s_axis_tdata,
    // AXI-Stream - OUTPUT
    input  wire                                m_axis_tready,
    output wire                                m_axis_tvalid,
    output wire                                m_axis_sof,     // Start of frame
    output wire [                        31:0] m_axis_tdata
);


  // **Wires
  wire [31:0] w_prbs_out;
  wire        w_reg_tx_enable;
  wire        w_reg_prbs_reload;
  wire        w_prbs_run;
  wire [31:0] w_reg_prbs_seed;

  // **Registers
  reg         r_axis_tvalid;
  reg         r_axis_sof;
  reg  [31:0] r_axis_tdata;
  reg         r_reg_tx_enable_d;

  // Assignment
  assign m_axis_tvalid = r_axis_tvalid;
  assign m_axis_sof    = r_axis_sof;
  assign m_axis_tdata  = r_axis_tdata;

  assign w_prbs_run = w_reg_tx_enable && m_axis_tready && s_axis_tvalid;
  assign s_axis_tready = w_reg_tx_enable && m_axis_tready;


  // -----------------------
  // Axi Bus Interface S_AXI
  // -----------------------
  tx_axi_slave #(
      .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
      .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
  ) tx_axi_slave_inst (
      // Control Registers
      .o_reg_tx_enable  (w_reg_tx_enable),
      .o_reg_prbs_reload(w_reg_prbs_reload),
      .o_reg_prbs_seed  (w_reg_prbs_seed),
      // AXI interface
      .S_AXI_ACLK       (s_axi_aclk),
      .S_AXI_ARESETN    (s_axi_aresetn),
      .S_AXI_AWADDR     (s_axi_awaddr),
      .S_AXI_AWPROT     (s_axi_awprot),
      .S_AXI_AWVALID    (s_axi_awvalid),
      .S_AXI_AWREADY    (s_axi_awready),
      .S_AXI_WDATA      (s_axi_wdata),
      .S_AXI_WSTRB      (s_axi_wstrb),
      .S_AXI_WVALID     (s_axi_wvalid),
      .S_AXI_WREADY     (s_axi_wready),
      .S_AXI_BRESP      (s_axi_bresp),
      .S_AXI_BVALID     (s_axi_bvalid),
      .S_AXI_BREADY     (s_axi_bready),
      .S_AXI_ARADDR     (s_axi_araddr),
      .S_AXI_ARPROT     (s_axi_arprot),
      .S_AXI_ARVALID    (s_axi_arvalid),
      .S_AXI_ARREADY    (s_axi_arready),
      .S_AXI_RDATA      (s_axi_rdata),
      .S_AXI_RRESP      (s_axi_rresp),
      .S_AXI_RVALID     (s_axi_rvalid),
      .S_AXI_RREADY     (s_axi_rready)
  );

  // -----------------------
  // PRBS Generator (Keystream)
  // -----------------------
  prbs prbs_inst (
      .i_aclk       (s_axi_aclk),
      .i_aresetn    (s_axi_aresetn),
      .i_prbs_run   (w_prbs_run),
      .i_prbs_reload(w_reg_prbs_reload),
      .i_prbs_seed  (w_reg_prbs_seed),
      .o_prbs       (w_prbs_out)
  );


  // AXI-Stream Master
  // Cipher
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (s_axi_aresetn == 1'b0) begin
      r_axis_tvalid <= 1'b0;
      r_axis_sof    <= 1'b0;
      r_axis_tdata  <= 'd0;
      r_reg_tx_enable_d <= 1'b0;
    end else begin
      //msh
      r_reg_tx_enable_d <= w_reg_tx_enable;

      if (m_axis_tready == 1'b1) begin
        // TODO: add logic to handle start of frame
        r_axis_sof <= 1'b0;

        if (r_reg_tx_enable_d == 1'b1 && s_axis_tvalid == 1'b1) begin
          r_axis_tvalid <= 1'b1;
          r_axis_tdata  <= w_prbs_out ^ s_axis_tdata;
        end else begin
          r_axis_tvalid <= 1'b0;
        end
      end
    end
  end

endmodule

