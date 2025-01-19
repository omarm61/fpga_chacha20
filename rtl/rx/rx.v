module rx #(
    // Input Clock in MHz
    parameter integer C_CLOCK_FREQ = 100,

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
    output wire        s_axis_tready,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_sof,     // Start of frame
    input  wire        s_axis_eof,     // Start of frame
    input  wire [31:0] s_axis_tdata,

    // AXI-Stream - OUTPUT
    input  wire        m_axis_tready,
    output wire        m_axis_tvalid,
    output wire [31:0] m_axis_tdata
);


  // **Wires
  wire [31:0] w_prbs_out;
  wire [31:0] w_reg_prbs_seed;
  wire        w_reg_rx_enable;
  wire        w_reg_key_reload;
  wire         w_reg_encrypt_type;
  wire [255:0] w_reg_chacha20_key;
  wire [ 95:0] w_reg_chacha20_nonce;
  wire         w_chacha20_error;
  wire         w_chacha20_req;
  wire         w_chacha20_busy;
  wire [ 31:0] w_chacha20_counter;
  wire [511:0] w_chacha20_keystream_data;
  wire         w_chacha20_keystream_valid;
  wire [ 31:0] w_keystream_data;
  wire         w_keystream_valid;
  wire         w_prbs_tready;
  wire         w_chacha20_tready;
  wire         w_keystream_available;


  // **Registers
  reg         r_axis_tready;
  reg         r_reg_rx_enable_d;
  reg  [31:0] r_rx_data;
  reg         r_rx_sof;
  reg         r_rx_eof;
  reg         r_prbs_run;
  reg  [31:0] r_axis_tdata;
  reg         r_axis_tvalid;

  // Assignment
  assign s_axis_tready = r_axis_tready;

  assign m_axis_tdata  = r_axis_tdata;
  assign m_axis_tvalid = r_axis_tvalid;


  // -----------------------
  // Axi Bus Interface S_AXI
  // -----------------------
  rx_axi_slave #(
      .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
      .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
  ) rx_axi_slave_inst (
      // Registers
      .o_reg_rx_enable      (w_reg_rx_enable),
      .o_reg_key_reload     (w_reg_key_reload),
      .o_reg_encrypt_type   (w_reg_encrypt_type),
      .o_reg_prbs_seed      (w_reg_prbs_seed),
      .o_reg_chacha20_key   (w_reg_chacha20_key),
      .o_reg_chacha20_nonce (w_reg_chacha20_nonce),
      // AXI Bus
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
  // PRBS Generator
  // -----------------------
  prbs prbs_inst (
      .i_aclk       (s_axi_aclk),
      .i_aresetn    (s_axi_aresetn),
      .i_prbs_run   (r_prbs_run),
      .i_prbs_reload(w_reg_key_reload),
      .i_prbs_seed  (w_reg_prbs_seed),
      .o_prbs       (w_prbs_out)
  );

  // -----------------------
  // ChaCha20 Cipher
  // -----------------------
  chacha20 chacha20_inst (
    // Clock, Reset
    .i_aclk           (s_axi_aclk),
    .i_aresetn        (s_axi_aresetn),
    // Control
    .i_keystream_req  (w_chacha20_req),
    .i_key_reload     (w_reg_key_reload),
    // Status
    .o_busy           (w_chacha20_busy),
    // Key
    .i_key            (w_reg_chacha20_key),
    // Nonce
    .i_nonce          (w_reg_chacha20_nonce),
    // Counter
    .i_counter        (w_chacha20_counter),
    // Output Cipher
    .o_keystream      (w_chacha20_keystream_data),
    .o_keystream_valid(w_chacha20_keystream_valid)
  );

  chacha20_stream chacha20_stream_inst (
    // Clock, Reset
    .i_aclk           (s_axi_aclk),
    .i_aresetn        (s_axi_aresetn),

    // Control
    .i_enable     (w_reg_encrypt_type && w_reg_rx_enable),
    .i_key_reload (w_reg_key_reload),
    // Status
    .o_error      (w_chacha20_error),
    // ChaCha20 Interface
    .o_chacha20_req             (w_chacha20_req),
    .i_chacha20_busy            (w_chacha20_busy),
    .o_chacha20_counter         (w_chacha20_counter),
    .i_chacha20_keystream_data  (w_chacha20_keystream_data),
    .i_chacha20_keystream_valid (w_chacha20_keystream_valid),
    // Output Stream, 32bit output
    .o_keystream_data  (w_keystream_data),
    .o_keystream_valid (w_keystream_valid),
    .i_keystream_ready (s_axis_tvalid && m_axis_tready),
    .o_keystream_available (w_keystream_available)
  );


  // TREADY Enable
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (s_axi_aresetn == 1'b0) begin
      r_axis_tready <= 1'b0;
      //msh
      r_reg_rx_enable_d <= 1'b0;
    end else begin
      // msh
      r_reg_rx_enable_d <= w_reg_rx_enable;

      if (w_reg_encrypt_type == 1'b0) begin
        // PRBS MODE
        // Enable AXI-Stream if reciever is enabled
        if (r_reg_rx_enable_d == 1'b1) begin
          r_axis_tready <= 1'b1;
        end
      end else begin
        // ChaCha20 MODE
        r_axis_tready <= w_keystream_valid || w_keystream_available;
      end
    end
  end

  // Capture AXI-Stream Data
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (s_axi_aresetn == 1'b0) begin
      r_rx_data <= 32'd0;
      r_rx_sof  <= 1'b0;
      r_rx_eof  <= 1'b0;
    end else begin
      // Check that tvalid is set before capturing data
      if (r_axis_tready && s_axis_tvalid) begin
        r_rx_data  <= s_axis_tdata;
        r_rx_sof   <= s_axis_sof;
        r_rx_eof   <= s_axis_eof;
        // Run PRBS generator
        r_prbs_run <= 1'b1;
      end else begin
        r_prbs_run <= 1'b0;
      end
    end
  end

  // FIXME: This logic can't handle back pressure. Need to stop transmission
  // when AXI-Stream is not ready to receive data
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (s_axi_aresetn == 1'b0) begin
      r_axis_tdata  <= 32'd0;
      r_axis_tvalid <= 1'b0;
    end else begin
      if (m_axis_tready) begin
        if (w_reg_encrypt_type == 1'b0) begin
          // PRBS MODE
          if (r_prbs_run) begin
            r_axis_tdata  <= r_rx_data ^ w_prbs_out;
            r_axis_tvalid <= 1'b1;
          end else begin
            r_axis_tvalid <= 1'b0;
          end
        end else begin
          // ChaCha20 MODE
          if (w_keystream_valid == 1'b1) begin
            r_axis_tdata  <= r_rx_data ^ w_keystream_data;
            r_axis_tvalid <= 1'b1;
          end else begin
            r_axis_tvalid <= 1'b0;
          end
        end
      end
    end
  end

endmodule
