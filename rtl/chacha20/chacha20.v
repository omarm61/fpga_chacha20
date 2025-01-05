module chacha20 (
    // Clock, Reset
    input wire i_aclk,
    input wire i_aresetn,
    // Control
    input wire i_enable,
    input wire i_start,
    // Key
    input wire [255:0] i_key,
    // Nonce
    input wire [95:0] i_nonce,
    // Counter
    input wire [31:0] i_counter,

    // Output Cipher
    output wire [511:0] o_keystream,
    output wire         o_keystream_valid
);

  genvar i_inst;
  integer i;

  // **Parameters
  localparam NUM_QUARTER_ROUND = 4;
  localparam NUM_ROUNDS = 10;

  localparam STATE_START = 0;
  localparam STATE_CALC_COLUMN = 1;
  localparam STATE_CALC_DIAGNOAL = 2;
  localparam STATE_OUTPUT_KEYSTREAM = 3;

  // **Registers
  reg  [ 2:0] r_state;
  reg  [31:0] r_state_matrix           [                 0:15];
  reg  [ 4:0] r_round_counter;

  reg  [31:0] r_quarter_round_in_a     [0:NUM_QUARTER_ROUND-1];
  reg  [31:0] r_quarter_round_in_b     [0:NUM_QUARTER_ROUND-1];
  reg  [31:0] r_quarter_round_in_c     [0:NUM_QUARTER_ROUND-1];
  reg  [31:0] r_quarter_round_in_d     [0:NUM_QUARTER_ROUND-1];
  reg         r_quarter_round_in_valid [0:NUM_QUARTER_ROUND-1];

  // **Wires
  wire [31:0] w_quarter_round_out_a    [0:NUM_QUARTER_ROUND-1];
  wire [31:0] w_quarter_round_out_b    [0:NUM_QUARTER_ROUND-1];
  wire [31:0] w_quarter_round_out_c    [0:NUM_QUARTER_ROUND-1];
  wire [31:0] w_quarter_round_out_d    [0:NUM_QUARTER_ROUND-1];
  wire        w_quarter_round_out_valid[0:NUM_QUARTER_ROUND-1];


  always @(posedge i_aclk or negedge i_aresetn) begin
    if (i_aresetn == 1'b0) begin
      for (i = 0; i < 15; i = i + 1) begin
        r_state_matrix <= 'd0;
      end
      for (i = 0; i < NUM_QUARTER_ROUND - 1; i = i + 1) begin
        r_quarter_round_in_a <= 'd0;
        r_quarter_round_in_b <= 'd0;
        r_quarter_round_in_c <= 'd0;
        r_quarter_round_in_d <= 'd0;
        r_quarter_round_in_valid <= 1'b0;
      end
      r_state <= STATE_START;
      r_round_counter <= 'd0;
    end else begin
      case (r_state)
        STATE_START: begin
          // initialize matrix
          // Constant
          r_state_matrix[0] <= 32'h61707865;
          r_state_matrix[1] <= 32'h3320646e;
          r_state_matrix[2] <= 32'h79622d32;
          r_state_matrix[3] <= 32'h6b206574;
          // key
          r_state_matrix[4:11] <= i_key;
          // Constant
          r_state_matrix[12] <= i_counter;
          // Nonce
          r_state_matrix[13:15] <= i_nonce;
          // Start Cipher
          if (i_start) begin
            r_round_counter <= 'd0;
            r_state <= STATE_CALC_COLUMN;
          end
        end
        STATE_CALC_COLUMN: begin
          for (i = 0; i < NUM_QUARTER_ROUND - 1; i = i + 1) begin
            r_quarter_round_in_a[i] <= r_state_matrix[0+i];
            r_quarter_round_in_b[i] <= r_state_matrix[4+i];
            r_quarter_round_in_c[i] <= r_state_matrix[8+i];
            r_quarter_round_in_d[i] <= r_state_matrix[12+i];
          end

          // Wait for quarter round to complete
          if (w_quarter_round_out_valid[0:3] == 4'b1111) begin
            // Update state matrix
            for (i = 0; i < NUM_QUARTER_ROUND - 1; i = i + 1) begin
              r_state_matrix[0+i]  <= w_quarter_round_out_a[i];
              r_state_matrix[4+i]  <= w_quarter_round_out_b[i];
              r_state_matrix[8+i]  <= w_quarter_round_out_c[i];
              r_state_matrix[12+i] <= w_quarter_round_out_d[i];
            end
            r_quarter_round_in_valid[0:3] <= 4'b0000;
            r_state <= STATE_CALC_DIAGNOAL;
          end else begin
            r_quarter_round_in_valid[0:3] <= 4'b1111;
          end
        end
        STATE_CALC_DIAGNOAL: begin
          // a
          for (i = 0; i < NUM_QUARTER_ROUND - 1; i = i + 1) begin
            r_quarter_round_in_a[i] <= r_state_matrix[0+i];
          end
          // b
          r_quarter_round_in_b[0] <= r_state_matrix[5];
          r_quarter_round_in_b[1] <= r_state_matrix[6];
          r_quarter_round_in_b[2] <= r_state_matrix[7];
          r_quarter_round_in_b[3] <= r_state_matrix[4];
          // c
          r_quarter_round_in_c[0] <= r_state_matrix[10];
          r_quarter_round_in_c[1] <= r_state_matrix[11];
          r_quarter_round_in_c[2] <= r_state_matrix[8];
          r_quarter_round_in_c[3] <= r_state_matrix[9];
          // d
          r_quarter_round_in_d[0] <= r_state_matrix[15];
          r_quarter_round_in_d[1] <= r_state_matrix[12];
          r_quarter_round_in_d[2] <= r_state_matrix[13];
          r_quarter_round_in_d[3] <= r_state_matrix[14];

          // Wait for quarter round to complete
          if (w_quarter_round_out_valid[0:3] == 4'b1111) begin
            // Update state matrix
            for (i = 0; i < NUM_QUARTER_ROUND - 1; i = i + 1) begin
              r_state_matrix[0+i] <= w_quarter_round_out_a[i];
            end
            //b
            r_state_matrix[5] <= w_quarter_round_out_b[0];
            r_state_matrix[6] <= w_quarter_round_out_b[1];
            r_state_matrix[7] <= w_quarter_round_out_b[2];
            r_state_matrix[4] <= w_quarter_round_out_b[3];
            //c
            r_state_matrix[10] <= w_quarter_round_out_c[0];
            r_state_matrix[11] <= w_quarter_round_out_c[1];
            r_state_matrix[8] <= w_quarter_round_out_c[2];
            r_state_matrix[9] <= w_quarter_round_out_c[3];
            //d
            r_state_matrix[15] <= w_quarter_round_out_d[0];
            r_state_matrix[12] <= w_quarter_round_out_d[1];
            r_state_matrix[13] <= w_quarter_round_out_d[2];
            r_state_matrix[14] <= w_quarter_round_out_d[3];

            r_quarter_round_in_valid[0:3] <= 4'b0000;
            if (r_round_counter >= NUM_ROUNDS) begin
              r_round_counter <= 'd0;
              r_state <= STATE_OUTPUT_KEYSTREAM;
            end else begin
              r_round_counter <= r_round_counter + 1;
              r_state <= STATE_CALC_COLUMN;
            end
          end else begin
            r_quarter_round_in_valid[0:3] <= 4'b1111;
          end

        end
        STATE_UPDATE_MATRIX: begin

        end
        default: r_state <= STATE_START;
      endcase
    end
  end

  generate
    for (i_inst = 0; i_inst < NUM_QUARTER_ROUND - 1; i_inst = i_inst + 1) begin : gen_quarter_round
      quarter_round #(
          .DATA_WIDTH(32)
      ) quarter_round_inst (
          // Clock, Reset
          .i_aclk   (i_aclk),
          .i_aresetn(i_aresetn),
          // Input A, B, C, D
          .i_a      (r_quarter_round_in_a[i_inst]),
          .i_b      (r_quarter_round_in_b[i_inst]),
          .i_c      (r_quarter_round_in_c[i_inst]),
          .i_d      (r_quarter_round_in_d[i_inst]),
          .i_valid  (r_quarter_round_in_valid[i_inst]),
          // Output
          .o_a      (w_quarter_round_out_a[i_inst]),
          .o_b      (w_quarter_round_out_b[i_inst]),
          .o_c      (w_quarter_round_out_c[i_inst]),
          .o_d      (w_quarter_round_out_d[i_inst]),
          .o_valid  (w_quarter_round_out_valid[i_inst])
      );
    end
  endgenerate

endmodule
