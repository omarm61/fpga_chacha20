module prbs (
    input  wire        i_aclk,
    input  wire        i_aresetn,
    input  wire        i_prbs_run,     // progress PRBS code
    input  wire        i_prbs_reload,  // set PRBS to the default ssed value
    input  wire [31:0] i_prbs_seed,
    output wire [31:0] o_prbs
);
  //
  // Fibonacci PRBS?
  // y = x^32 + x^5 + 1
  // **Parameters
  localparam PRBS_LENGTH = 32;

  // **Registers
  reg [PRBS_LENGTH-1:0] r_prbs;

  // **Wires
  assign o_prbs = r_prbs;

  // Prbs Shifter
  always @(posedge i_aclk or negedge i_aresetn) begin
    if (i_aresetn == 1'b0) begin
      r_prbs <= 32'hACE1;
    end else begin
      if (i_prbs_reload == 1'b1) begin
        r_prbs <= i_prbs_seed;
      end else begin
        if (i_prbs_run == 1'b1) begin
          r_prbs <= {
            r_prbs[PRBS_LENGTH-2:0],
            r_prbs[PRBS_LENGTH-1] ^ r_prbs[PRBS_LENGTH-16-1] ^ r_prbs[PRBS_LENGTH-5-1]
          };
        end
      end
    end
  end

endmodule
