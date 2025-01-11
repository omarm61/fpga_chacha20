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
  localparam NUM_ROUNDS        = 10;

  localparam STATE_START              = 0;
  localparam STATE_CALC_COLUMN_REQ    = 1;
  localparam STATE_CALC_COLUMN_WAIT   = 2;
  localparam STATE_CALC_DIAGNOAL_REQ  = 3;
  localparam STATE_CALC_DIAGNOAL_WAIT = 4;
  localparam STATE_OUTPUT_KEYSTREAM   = 5;

  // **Registers
  reg [$clog2(STATE_OUTPUT_KEYSTREAM):0] r_state;
  reg [31:0] r_state_matrix      [0:15];
  reg [31:0] r_state_matrix_init [0:15];
  reg [ 4:0] r_round_counter;

  reg  [31:0] r_quarter_round_in_a     [0:NUM_QUARTER_ROUND-1];
  reg  [31:0] r_quarter_round_in_b     [0:NUM_QUARTER_ROUND-1];
  reg  [31:0] r_quarter_round_in_c     [0:NUM_QUARTER_ROUND-1];
  reg  [31:0] r_quarter_round_in_d     [0:NUM_QUARTER_ROUND-1];
  reg  [NUM_QUARTER_ROUND-1:0] r_quarter_round_in_valid;
  reg          r_keystream_valid;
  reg  [511:0] r_keystream_data;

  // **Wires
  wire [31:0] w_quarter_round_out_a    [0:NUM_QUARTER_ROUND-1];
  wire [31:0] w_quarter_round_out_b    [0:NUM_QUARTER_ROUND-1];
  wire [31:0] w_quarter_round_out_c    [0:NUM_QUARTER_ROUND-1];
  wire [31:0] w_quarter_round_out_d    [0:NUM_QUARTER_ROUND-1];
  wire [NUM_QUARTER_ROUND-1:0] w_quarter_round_out_valid;
  wire [NUM_QUARTER_ROUND-1:0] w_quarter_round_out_busy;
  wire [31:0] w_keystream_adder        [0:15];


  always @(posedge i_aclk or negedge i_aresetn) begin
    if (i_aresetn == 1'b0) begin
      for (i = 0; i < 15; i = i + 1) begin
        r_state_matrix[i] <= 'd0;
        r_state_matrix_init[i] <= 'd0;
      end
      for (i = 0; i < NUM_QUARTER_ROUND - 1; i = i + 1) begin
        r_quarter_round_in_a[i] <= 'd0;
        r_quarter_round_in_b[i] <= 'd0;
        r_quarter_round_in_c[i] <= 'd0;
        r_quarter_round_in_d[i] <= 'd0;
        r_quarter_round_in_valid[i] <= 1'b0;
      end
      r_state <= STATE_START;
      r_round_counter <= 'd0;
    end else begin
      case (r_state)
        STATE_START: begin
          r_keystream_valid <= 1'b0;
          // initialize matrix
          // Constant
          r_state_matrix[0] <= 32'h61707865;
          r_state_matrix[1] <= 32'h3320646e;
          r_state_matrix[2] <= 32'h79622d32;
          r_state_matrix[3] <= 32'h6b206574;
          r_state_matrix_init[0] <= 32'h61707865;
          r_state_matrix_init[1] <= 32'h3320646e;
          r_state_matrix_init[2] <= 32'h79622d32;
          r_state_matrix_init[3] <= 32'h6b206574;
          // key
          for (i = 0; i < 8; i = i + 1) begin
            r_state_matrix[4+i] <= i_key[32*i+:32];
            r_state_matrix_init[4+i] <= i_key[32*i+:32];
          end
          // Constant
          r_state_matrix[12] <= i_counter;
          r_state_matrix_init[12] <= i_counter;
          // Nonce
          for (i = 0; i < 3; i = i + 1) begin
            r_state_matrix[13+i] <= i_nonce[32*i+:32];
            r_state_matrix_init[13+i] <= i_nonce[32*i+:32];
          end
          // Start Cipher
          // FIXME: check that next module is ready for next keystream before
          // generating a new value
          if (i_start) begin
            r_round_counter <= 'd0;
            r_state <= STATE_CALC_COLUMN_REQ;
          end
        end
        STATE_CALC_COLUMN_REQ: begin
          // Request a new column calculation
          for (i = 0; i < NUM_QUARTER_ROUND; i = i + 1) begin
            if (w_quarter_round_out_busy[i] == 1'b0) begin
              r_quarter_round_in_a[i] <= r_state_matrix[0+i];
              r_quarter_round_in_b[i] <= r_state_matrix[4+i];
              r_quarter_round_in_c[i] <= r_state_matrix[8+i];
              r_quarter_round_in_d[i] <= r_state_matrix[12+i];
              r_quarter_round_in_valid[i] <= 1'b1;
            end
          end
          // Next state
          if (r_quarter_round_in_valid[3:0] == 4'b1111) begin
            r_state <= STATE_CALC_COLUMN_WAIT;
          end
        end
        STATE_CALC_COLUMN_WAIT: begin
          // Wait for the quarter round to output valid data
            // Update state matrix
            for (i = 0; i < NUM_QUARTER_ROUND; i = i + 1) begin
              if (w_quarter_round_out_valid[i] == 1'b1) begin
                r_state_matrix[0+i] <= w_quarter_round_out_a[i];
                r_state_matrix[4+i] <= w_quarter_round_out_b[i];
                r_state_matrix[8+i] <= w_quarter_round_out_c[i];
                r_state_matrix[12+i] <= w_quarter_round_out_d[i];
                r_quarter_round_in_valid[i] <= 1'b0;
              end
            end

            // Move to next state if all quarter rounds are done
            if (w_quarter_round_out_valid[3:0] == 4'b1111) begin
              r_state <= STATE_CALC_DIAGNOAL_REQ;
            end
        end
        STATE_CALC_DIAGNOAL_REQ: begin
            // a
            for (i = 0; i < NUM_QUARTER_ROUND; i = i + 1) begin
              if (w_quarter_round_out_busy[i] == 1'b0) begin
                r_quarter_round_in_a[i] <= r_state_matrix[0+i];
                r_quarter_round_in_valid[i] <= 1'b1;
                case(i)
                  0: begin
                    r_quarter_round_in_b[0] <= r_state_matrix[5];
                    r_quarter_round_in_c[0] <= r_state_matrix[10];
                    r_quarter_round_in_d[0] <= r_state_matrix[15];
                  end
                  1: begin
                    r_quarter_round_in_b[1] <= r_state_matrix[6];
                    r_quarter_round_in_c[1] <= r_state_matrix[11];
                    r_quarter_round_in_d[1] <= r_state_matrix[12];
                  end
                  2: begin
                    r_quarter_round_in_b[2] <= r_state_matrix[7];
                    r_quarter_round_in_c[2] <= r_state_matrix[8];
                    r_quarter_round_in_d[2] <= r_state_matrix[13];
                  end
                  3: begin
                    r_quarter_round_in_b[3] <= r_state_matrix[4];
                    r_quarter_round_in_c[3] <= r_state_matrix[9];
                    r_quarter_round_in_d[3] <= r_state_matrix[14];
                  end
                  default: r_quarter_round_in_valid[i] <= 1'b0;
                endcase
              end
            end
            // Next State
            if (r_quarter_round_in_valid[3:0] == 4'b1111) begin
              r_state <= STATE_CALC_DIAGNOAL_WAIT;
            end
        end
        STATE_CALC_DIAGNOAL_WAIT: begin
            // Update state matrix
            for (i = 0; i < NUM_QUARTER_ROUND; i = i + 1) begin
              // Wait for quarter round to complete
              if (w_quarter_round_out_valid[i] == 1'b1) begin
                r_state_matrix[0+i] <= w_quarter_round_out_a[i];
                r_quarter_round_in_valid[i] <= 1'b0;
                case(i)
                  0: begin
                    r_state_matrix[5] <= w_quarter_round_out_b[0];
                    r_state_matrix[10] <= w_quarter_round_out_c[0];
                    r_state_matrix[15] <= w_quarter_round_out_d[0];
                  end
                  1: begin
                    r_state_matrix[6] <= w_quarter_round_out_b[1];
                    r_state_matrix[11] <= w_quarter_round_out_c[1];
                    r_state_matrix[12] <= w_quarter_round_out_d[1];
                  end
                  2: begin
                    r_state_matrix[7] <= w_quarter_round_out_b[2];
                    r_state_matrix[8] <= w_quarter_round_out_c[2];
                    r_state_matrix[13] <= w_quarter_round_out_d[2];
                  end
                  3: begin
                    r_state_matrix[4] <= w_quarter_round_out_b[3];
                    r_state_matrix[9] <= w_quarter_round_out_c[3];
                    r_state_matrix[14] <= w_quarter_round_out_d[3];
                  end
                  default: r_quarter_round_in_valid[i] <= 1'b0;
                endcase
              end
            end

            if (w_quarter_round_out_valid[3:0] == 4'b1111) begin
              if (r_round_counter >= NUM_ROUNDS-1) begin
                r_round_counter <= 'd0;
                r_state <= STATE_OUTPUT_KEYSTREAM;
              end else begin
                r_round_counter <= r_round_counter + 1;
                r_state <= STATE_CALC_COLUMN_REQ;
              end
            end
        end
        STATE_OUTPUT_KEYSTREAM: begin
          for (i = 0; i < 16; i = i + 1) begin
            r_keystream_data[(32*i)+:32] <= w_keystream_adder[i];
          end
          r_keystream_valid <= 1'b1;
          // Next State
          r_state <= STATE_START;

        end
        default: r_state <= STATE_START;
      endcase
    end
  end

  generate
    // Quarter Round
    for (i_inst = 0; i_inst < NUM_QUARTER_ROUND; i_inst = i_inst + 1) begin : gen_quarter_round
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
          .o_valid  (w_quarter_round_out_valid[i_inst]),
          .o_busy   (w_quarter_round_out_busy[i_inst])
      );
    end


    // Adders used to combine the calculated cipher with inital state matrix
    for (i_inst = 0; i_inst < 16; i_inst = i_inst + 1) begin : gen_keystream_adder
      adder #(
          .DATA_WIDTH(32)
      ) adder_keystream (
          // Clock, Reset
          .i_aclk   (i_aclk),
          .i_aresetn(i_aresetn),
          // Input A + B
          .i_a      (r_state_matrix[i_inst]),
          .i_b      (r_state_matrix_init[i_inst]),
          // Output
          .o_output (w_keystream_adder[i_inst])
      );
    end
  endgenerate

endmodule
