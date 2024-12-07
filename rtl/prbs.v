module prbs(
  input wire         i_aclk,
  input wire         i_aresetn,
  input wire         i_start,
  input wire  [31:0]  i_prbs_seed,
  output wire [31:0] o_prbs
);

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
  end
  else begin
    // FIXME: this sequence is incorrect
    if (i_start) begin
      r_prbs <= {
                r_prbs[PRBS_LENGTH-2:0], 
                r_prbs[PRBS_LENGTH-1]^r_prbs[PRBS_LENGTH-16-1]^r_prbs[PRBS_LENGTH-5-1]
      };
    end
  end
end

endmodule
