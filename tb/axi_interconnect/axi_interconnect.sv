module axi_interconnect #(
    parameter  NUM_AXI_INTF = 2
) (
    // Master AXI-Lite - M
    axi_if.slave axi_s,

    // Slave AXI-Lite - S00
    axi_if.master axi_m[NUM_AXI_INTF]
);

// **Parameters

// **Wires
genvar index;

generate
    for (index = 0; index < NUM_AXI_INTF; index = index + 1) begin
        always @(*) begin
            if ( ((axi_s.araddr[31:28] == index) && axi_s.arvalid == 1'b1) || ((axi_s.awaddr[31:28] == index) && axi_s.awvalid == 1'b1)) begin
                // Connect
                // Slave -> Master
                axi_m[index].awid    = axi_s.awid;
                axi_m[index].awaddr  = axi_s.awaddr;
                axi_m[index].awvalid = axi_s.awvalid;
                axi_m[index].wdata   = axi_s.wdata;
                axi_m[index].wstrb   = axi_s.wstrb;
                axi_m[index].wvalid  = axi_s.wvalid;
                axi_m[index].bready  = axi_s.bready;
                axi_m[index].awburst = axi_s.awburst; // INCR
                axi_m[index].awcache = axi_s.awcache;
                axi_m[index].awlen   = axi_s.awlen;
                axi_m[index].awsize  = axi_s.awsize; // 4 bytes
                axi_m[index].awlock  = axi_s.awlock;
                axi_m[index].wlast   = axi_s.wlast;
                axi_m[index].arid    = axi_s.arid;
                axi_m[index].araddr  = axi_s.araddr;
                axi_m[index].arvalid = axi_s.arvalid;
                axi_m[index].rready  = axi_s.rready;
                axi_m[index].arburst = axi_s.arburst; // INCR
                axi_m[index].arcache = axi_s.arcache;
                axi_m[index].arlen   = axi_s.arlen;
                axi_m[index].arsize  = axi_s.arsize; // 4 bytes
                axi_m[index].arlock  = axi_s.arlock;

                // Master -> Slave
                axi_s.awready = axi_m[index].awready;
                axi_s.wready  = axi_m[index].wready;
                axi_s.bid     = axi_m[index].bid;
                axi_s.bresp   = axi_m[index].bresp;
                axi_s.bvalid  = axi_m[index].bvalid;
                axi_s.arready = axi_m[index].arready;
                axi_s.rid     = axi_m[index].rid;
                axi_s.rdata   = axi_m[index].rdata;
                axi_s.rresp   = axi_m[index].rresp;
                axi_s.rvalid  = axi_m[index].rvalid;
                axi_s.rlast   = axi_m[index].rlast;
            end
            else begin
                // Disconnect
                // -------------
                axi_m[index].awid    = 'd0;
                axi_m[index].awaddr  = 'd0;
                axi_m[index].awvalid = 'd0;
                axi_m[index].wdata   = 'd0;
                axi_m[index].wstrb   = 'd0;
                axi_m[index].wvalid  = 'd0;
                axi_m[index].bready  = 'd0;
                axi_m[index].awburst = 'd0;
                axi_m[index].awcache = 'd0;
                axi_m[index].awlen   = 'd0;
                axi_m[index].awsize  = 'd0;
                axi_m[index].awlock  = 'd0;
                axi_m[index].wlast   = 'd0;
                axi_m[index].arid    = 'd0;
                axi_m[index].araddr  = 'd0;
                axi_m[index].arvalid = 'd0;
                axi_m[index].rready  = 'd0;
                axi_m[index].arburst = 'd0;
                axi_m[index].arcache = 'd0;
                axi_m[index].arlen   = 'd0;
                axi_m[index].arsize  = 'd0;
                axi_m[index].arlock  = 'd0;

            end
        end
    end
endgenerate


endmodule

