// CONTENTS
// =========================================
// 77 : Componennts
// 80 : ___
// 81 : Zynq FPGA
// 82 :   - AXI Interconnect
// 122: ___
// 123:   - PRBS Transmitter
// -----------------------------------------

`timescale 1ns / 1ps

`include "interfaces.sv"

module tb_fpga (
    input wire s_axi_aclk,
    input wire s_axi_aresetn,

    // Transmitter. AXI-Stream Output
    output wire        m_axis_tready,
    output wire        m_axis_tvalid,
    output wire        m_axis_sof,
    output wire [31:0] m_axis_tdata,


    // Ports of Axi Slave Bus Interface S00_AXI
    input  wire [      31 : 0] s_axi_awaddr,
    input  wire [       2 : 0] s_axi_awprot,
    input  wire                s_axi_awvalid,
    output wire                s_axi_awready,
    input  wire [      31 : 0] s_axi_wdata,
    input  wire [(32/8)-1 : 0] s_axi_wstrb,
    input  wire                s_axi_wvalid,
    output wire                s_axi_wready,
    output wire [       1 : 0] s_axi_bresp,
    output wire                s_axi_bvalid,
    input  wire                s_axi_bready,
    input  wire [    32-1 : 0] s_axi_araddr,
    input  wire [       2 : 0] s_axi_arprot,
    input  wire                s_axi_arvalid,
    output wire                s_axi_arready,
    output wire [    32-1 : 0] s_axi_rdata,
    output wire [       1 : 0] s_axi_rresp,
    output wire                s_axi_rvalid,
    input  wire                s_axi_rready
);

  // **Parameters
  localparam integer NUM_AXI_INTF = 2;

  // **Wires


  axi_if axi_s ();
  axi_if axi_m[NUM_AXI_INTF] ();

  // **Registers


  // DUT
  // INDEX: Componennts

  // --------------------------------------
  // INDEX: ___
  // INDEX: Zynq FPGA
  // INDEX:   - AXI Interconnect
  // Description: Covnert SPI data to AXI Stream data
  // --------------------------------------
  assign axi_s.awaddr  = s_axi_awaddr;
  assign axi_s.awprot  = s_axi_awprot;
  assign axi_s.awvalid = s_axi_awvalid;

  assign s_axi_awready = axi_s.awready;

  assign axi_s.wdata   = s_axi_wdata;
  assign axi_s.wstrb   = s_axi_wstrb;
  assign axi_s.wvalid  = s_axi_wvalid;

  assign s_axi_wready  = axi_s.wready;
  assign s_axi_bresp   = axi_s.bresp;
  assign s_axi_bvalid  = axi_s.bvalid;

  assign axi_s.bready  = s_axi_bready;
  assign axi_s.araddr  = s_axi_araddr;
  assign axi_s.arprot  = s_axi_arprot;
  assign axi_s.arvalid = s_axi_arvalid;

  assign s_axi_arready = axi_s.arready;
  assign s_axi_rdata   = axi_s.rdata;
  assign s_axi_rresp   = axi_s.rresp;
  assign s_axi_rvalid  = axi_s.rvalid;

  assign axi_s.rready  = s_axi_rready;

  axi_interconnect #(
      .NUM_AXI_INTF(NUM_AXI_INTF)
  ) axi_interconnect_inst (
      // AXI-Slave S00 sim_top.c
      .axi_s(axi_s.slave),
      // AXI-Msater M00
      .axi_m(axi_m)
  );


  // --------------------------------------
  // INDEX: ___
  // INDEX:   - PRBS Transmitter
  // Description: TTL interface
  // --------------------------------------
  tx #(
      // Parameters of Axi Slave Bus Interface S_AXI
      .C_S_AXI_DATA_WIDTH(32),
      .C_S_AXI_ADDR_WIDTH(32)
  ) tx_inst (

      // Ports of Axi Slave Bus Interface S_AXI
      .s_axi_aclk   (s_axi_aclk),
      .s_axi_aresetn(s_axi_aresetn),
      .s_axi_awaddr (axi_m[0].awaddr),
      .s_axi_awprot (axi_m[0].awprot),
      .s_axi_awvalid(axi_m[0].awvalid),
      .s_axi_awready(axi_m[0].awready),
      .s_axi_wdata  (axi_m[0].wdata),
      .s_axi_wstrb  (axi_m[0].wstrb),
      .s_axi_wvalid (axi_m[0].wvalid),
      .s_axi_wready (axi_m[0].wready),
      .s_axi_bresp  (axi_m[0].bresp),
      .s_axi_bvalid (axi_m[0].bvalid),
      .s_axi_bready (axi_m[0].bready),
      .s_axi_araddr (axi_m[0].araddr),
      .s_axi_arprot (axi_m[0].arprot),
      .s_axi_arvalid(axi_m[0].arvalid),
      .s_axi_arready(axi_m[0].arready),
      .s_axi_rdata  (axi_m[0].rdata),
      .s_axi_rresp  (axi_m[0].rresp),
      .s_axi_rvalid (axi_m[0].rvalid),
      .s_axi_rready (axi_m[0].rready),

      // AXI-Stream - OUTPUT encrypted data
      .m_axis_tready(m_axis_tready),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_sof   (m_axis_sof),     // Start of frame
      .m_axis_tdata (m_axis_tdata)
  );

  // --------------------------------------
  // INDEX: ___
  // INDEX:   - PRBS Transmitter
  // Description: TTL interface
  // --------------------------------------
  rx #(
      // Parameters of Axi Slave Bus Interface S_AXI
      .C_S_AXI_DATA_WIDTH(32),
      .C_S_AXI_ADDR_WIDTH(32)
  ) rx_inst (

      // Ports of Axi Slave Bus Interface S_AXI
      .s_axi_aclk   (s_axi_aclk),
      .s_axi_aresetn(s_axi_aresetn),
      .s_axi_awaddr (axi_m[1].awaddr),
      .s_axi_awprot (axi_m[1].awprot),
      .s_axi_awvalid(axi_m[1].awvalid),
      .s_axi_awready(axi_m[1].awready),
      .s_axi_wdata  (axi_m[1].wdata),
      .s_axi_wstrb  (axi_m[1].wstrb),
      .s_axi_wvalid (axi_m[1].wvalid),
      .s_axi_wready (axi_m[1].wready),
      .s_axi_bresp  (axi_m[1].bresp),
      .s_axi_bvalid (axi_m[1].bvalid),
      .s_axi_bready (axi_m[1].bready),
      .s_axi_araddr (axi_m[1].araddr),
      .s_axi_arprot (axi_m[1].arprot),
      .s_axi_arvalid(axi_m[1].arvalid),
      .s_axi_arready(axi_m[1].arready),
      .s_axi_rdata  (axi_m[1].rdata),
      .s_axi_rresp  (axi_m[1].rresp),
      .s_axi_rvalid (axi_m[1].rvalid),
      .s_axi_rready (axi_m[1].rready),

      // AXI-Stream - INPUT encrypted data
      .s_axis_tready(m_axis_tready),
      .s_axis_tvalid(m_axis_tvalid),
      .s_axis_sof   (m_axis_sof),     // Start of frame
      .s_axis_tdata (m_axis_tdata)
  );

endmodule
