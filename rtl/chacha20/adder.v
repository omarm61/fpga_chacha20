
module adder #(
    parameter integer DATA_WIDTH = 32
) (
    // Clock, Reset
    input wire i_aclk,
    input wire i_aresetn,
    // Input A + B
    input wire [DATA_WIDTH-1:0] i_a,
    input wire [DATA_WIDTH-1:0] i_b,
    // Output
    output wire [DATA_WIDTH-1:0] o_output
);


  // **Registers
  reg [DATA_WIDTH] r_output;

  assign o_output = r_output;

  always @(posedge i_aclk or negedge i_aresetn) begin
    if (i_aresetn == 1'b0) begin
      r_output <= 'd0;
    end else begin
      r_output <= i_a + i_b;
    end
  end

endmodule
