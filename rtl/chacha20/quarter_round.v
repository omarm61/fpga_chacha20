
module quarter_round #(
    parameter integer DATA_WIDTH = 32
) (
    // Clock, Reset
    input  wire                  i_aclk,
    input  wire                  i_aresetn,
    // Input A, B, C, D
    input  wire [DATA_WIDTH-1:0] i_a,
    input  wire [DATA_WIDTH-1:0] i_b,
    input  wire [DATA_WIDTH-1:0] i_c,
    input  wire [DATA_WIDTH-1:0] i_d,
    input  wire                  i_valid,
    // Output
    output wire [DATA_WIDTH-1:0] o_a,
    output wire [DATA_WIDTH-1:0] o_b,
    output wire [DATA_WIDTH-1:0] o_c,
    output wire [DATA_WIDTH-1:0] o_d,
    output wire                  o_valid,
    output wire                  o_busy
);

  // **Parameters
  localparam STATE_START = 0;
  localparam STATE_CALC_AD1 = 1;
  localparam STATE_CALC_CB1 = 2;
  localparam STATE_CALC_AD2 = 3;
  localparam STATE_CALC_CB2 = 4;

  // **Registers
  reg [$clog2(STATE_CALC_CB2):0] r_state;

  reg r_valid;
  reg [31:0] r_a_in;
  reg [31:0] r_b_in;
  reg [31:0] r_c_in;
  reg [31:0] r_d_in;
  reg [31:0] r_a_out;
  reg [31:0] r_b_out;
  reg [31:0] r_c_out;
  reg [31:0] r_d_out;
  reg r_busy;

  // **Wires
  wire [31:0] w_a1;
  wire [31:0] w_b1;
  wire [31:0] w_c1;
  wire [31:0] w_d1;
  wire [31:0] w_a2;
  wire [31:0] w_b2;
  wire [31:0] w_c2;
  wire [31:0] w_d2;
  wire [31:0] w_d1_lshift;
  wire [31:0] w_b1_lshift;
  wire [31:0] w_d2_lshift;
  wire [31:0] w_b2_lshift;

  // Assignments
  assign o_a = r_a_out;
  assign o_b = r_b_out;
  assign o_c = r_c_out;
  assign o_d = r_d_out;
  assign o_valid = r_valid;
  assign o_busy = r_busy;

  // FSM
  // STATE_WAIT: Wait for next round of data
  // STATE_CALC_AD1: a = a + b; d = (d XOR a) <<< 16
  // STATE_CALC_CB1: c = c + d; b = (b XOR c) <<< 12
  // STATE_CALC_AD2: a = a + b; d = (d XOR a) <<< 8
  // STATE_CALC_CB2: c = c + d; b = (b XOR c) <<< 7
  always @(posedge i_aclk or negedge i_aresetn) begin
    if (i_aresetn == 1'b0) begin
      r_state <= STATE_START;
      r_valid <= 1'b0;
      r_a_in  <= 32'd0;
      r_b_in  <= 32'd0;
      r_c_in  <= 32'd0;
      r_d_in  <= 32'd0;
      r_busy <= 1'b0;
    end else begin
      case (r_state)
        STATE_START: begin
          // Wait for valid data
          if (i_valid == 1'b1) begin
            r_state <= STATE_CALC_AD1;
            r_a_in  <= i_a;
            r_b_in  <= i_b;
            r_c_in  <= i_c;
            r_d_in  <= i_d;
            r_busy <= 1'b1;
          end else begin
            r_busy <= 1'b0;
          end
          r_valid <= 1'b0;
        end
        STATE_CALC_AD1: r_state <= STATE_CALC_CB1;
        STATE_CALC_CB1: r_state <= STATE_CALC_AD2;
        STATE_CALC_AD2: r_state <= STATE_CALC_CB2;
        STATE_CALC_CB2: begin
          r_a_out <= w_a2;
          r_b_out <= w_b2_lshift;
          r_c_out <= w_c2;
          r_d_out <= w_d2_lshift;
          r_valid <= 1'b1;
          if (i_valid == 1'b0) begin
            r_busy <= 1'b0;
            r_state <= STATE_START;
          end
        end
        default: begin
          r_state <= STATE_START;
          r_valid <= 1'b0;
        end
      endcase
    end
  end

  // STATE_CALC_AD1: a = a + b; d = (d XOR a) <<< 16
  adder #(
      .DATA_WIDTH(DATA_WIDTH)
  ) adder_ad1 (
      // Clock, Reset
      .i_aclk   (i_aclk),
      .i_aresetn(i_aresetn),
      // Input A + B
      .i_a      (r_a_in),
      .i_b      (r_b_in),
      // Output
      .o_output (w_a1)
  );
  assign w_d1 = r_d_in ^ w_a1;
  assign w_d1_lshift = {w_d1[15:0], w_d1[31:0]};


  // STATE_CALC_CB1: c = c + d; b = (b XOR c) <<< 12
  adder #(
      .DATA_WIDTH(DATA_WIDTH)
  ) adder_cb1 (
      // Clock, Reset
      .i_aclk   (i_aclk),
      .i_aresetn(i_aresetn),
      // Input A + B
      .i_a      (r_c_in),
      .i_b      (w_d1_lshift),
      // Output
      .o_output (w_c1)
  );
  assign w_b1 = r_b_in ^ w_c1;
  assign w_b1_lshift = {w_b1[11:0], w_b1[31:12]};

  // STATE_CALC_AD2: a = a + b; d = (d XOR a) <<< 8
  adder #(
      .DATA_WIDTH(DATA_WIDTH)
  ) adder_ad2 (
      // Clock, Reset
      .i_aclk   (i_aclk),
      .i_aresetn(i_aresetn),
      // Input A + B
      .i_a      (w_a1),
      .i_b      (w_b1_lshift),
      // Output
      .o_output (w_a2)
  );
  assign w_d2 = w_d1_lshift ^ w_a2;
  assign w_d2_lshift = {w_d2[7:0], w_d2[31:8]};

  // STATE_CALC_CB2: c = c + d; b = (b XOR c) <<< 7
  adder #(
      .DATA_WIDTH(DATA_WIDTH)
  ) adder_cb2 (
      // Clock, Reset
      .i_aclk   (i_aclk),
      .i_aresetn(i_aresetn),
      // Input A + B
      .i_a      (w_c1),
      .i_b      (w_d2_lshift),
      // Output
      .o_output (w_c2)
  );
  assign w_b2 = w_b1_lshift ^ w_c2;
  assign w_b2_lshift = {w_b2[6:0], w_b2[31:7]};

endmodule
