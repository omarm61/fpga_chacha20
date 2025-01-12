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

  // **Parameters
  localparam STATE_START = 0;
  localparam STATE_KEYSTREAM_WAIT = 1;
  localparam STATE_KEYSTREAM_UNPACK = 2;

  // **Wires
  wire [ 31:0] w_prbs_out;
  wire         w_reg_tx_enable;
  wire         w_reg_key_reload;
  wire         w_prbs_run;
  wire [ 31:0] w_reg_prbs_seed;
  wire [255:0] w_reg_chacha20_key;
  wire [ 95:0] w_reg_chacha20_nonce;
  wire [511:0] w_chacha20_keystream_data;
  wire         w_chacha20_keystream_valid;

  wire         w_keystream_valid;

  // **Registers
  reg  [  2:0] r_state;
  reg          r_axis_tvalid;
  reg          r_axis_sof;
  reg  [ 31:0] r_axis_tdata;
  reg          r_reg_tx_enable_d;
  reg          r_keystream_req;
  reg  [511:0] r_keystream_512bit;
  reg  [ 31:0] r_keystream_32bit;
  reg  [ 31:0] r_keystream_counter;
  reg  [  4:0] r_keystream_index;
  reg          r_keystream_valid;
  reg          r_chacha20_error;

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
      .o_reg_tx_enable      (w_reg_tx_enable),
      .o_reg_key_reload     (w_reg_key_reload),
      .o_reg_prbs_seed      (w_reg_prbs_seed),
      .o_reg_chacha20_key   (w_reg_chacha20_key),
      .o_reg_chacha20_nonce (w_reg_chacha20_nonce),
      // Status
      .i_chacha20_counter (r_chacha20_counter),
      .i_chacha20_error   (r_chacha20_error),
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
      .i_keystream_req  (w_reg_tx_enable),
      .i_key_reload     (w_reg_key_reload),
      // Status
      .o_busy           (w_chacha20_busy),
      // Key
      .i_key            (w_reg_chacha20_key),
      // Nonce
      .i_nonce          (w_reg_chacha20_nonce),
      // Counter
      .i_counter        (32'h0),
      // Output Cipher
      .o_keystream      (w_chacha20_keystream_data),
      .o_keystream_valid(w_chacha20_keystream_valid)
  );

  // ChaCha20 Keystream handler 256bit to 32bit intervals
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (s_axi_aresetn == 1'b0) begin
      r_keystream_req <= 1'b0;
      r_keystream_512bit  <= 'd0;
      r_keystream_32bit   <= 'd0;
      r_keystream_counter <= 'd0;
      r_keystream_index   <= 'd0;
      r_keystream_valid   <= 1'b0;
    end else begin
      case(r_state)
        STATE_START: begin
          if (w_reg_tx_enable == 1'b1 && w_chacha20_busy == 1'b0) begin
            // Request a new key
            r_keystream_req <= 1'b1;
            r_keystream_index <= 'd0;
            r_state <= STATE_KEYSTREAM_WAIT;
          end
          // Reset the counter if the key is reloaded
          if (w_reg_key_reload) begin
            r_keystream_counter <= 'd0;
          end
        end
        STATE_KEYSTREAM_WAIT: begin
          // Wait for valid keystream
          r_keystream_req <= 1'b0;
          if (w_chacha20_keystream_valid == 1'b1) begin
            r_keystream_512bit <= w_chacha20_keystream_data;
            r_keystream_32bit <= w_chacha20_keystream_data[31:0];
            r_keystream_valid <= 1'b1;
            r_keystream_index <= r_keystream_index + 1;
            r_chacha20_error <= 1'b0;
            r_state <= STATE_KEYSTREAM_UNPACK;
          end
          // error handling
          if (w_chacha20_busy == 1'b0) begin
            r_chacha20_error <= 1'b1;
            r_state <= STATE_START;
          end else begin
            r_chacha20_error <= 1'b0;
          end
        end
        STATE_KEYSTREAM_UNPACK: begin
          if (r_keystream_index < 5'd16) begin
            // NOTE: This syntax is not supported in older verilog
            r_keystream_32bit <= r_keystream_512bit[r_keystream_index*32+:32];
            r_keystream_index <= r_keystream_index + 1;
            r_keystream_valid <= 1'b1;
          end else begin
            r_state <= STATE_START;
            r_keystream_counter <= r_keystream_counter + 1;
            r_keystream_valid <= 1'b0;
            r_keystream_index <= 'd0;
          end
        end
        default: r_state <= STATE_START;
      endcase
    end
  end

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

