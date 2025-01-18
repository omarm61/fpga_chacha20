module chacha20_stream(
    // Clock, Reset
    input wire i_aclk,
    input wire i_aresetn,
    // Control
    input wire i_enable,
    input wire i_key_reload,
    // Error
    output wire o_error, // Error, failed to generate a keystream
    // ChaCha20 Interface
    output wire         o_chacha20_req,
    input  wire         i_chacha20_busy,
    output wire [ 31:0] o_chacha20_counter,
    input  wire [511:0] i_chacha20_keystream_data,
    input  wire         i_chacha20_keystream_valid,
    // Output Stream
    output wire [ 31:0] o_keystream_data,
    output wire         o_keystream_valid,
    input  wire         i_keystream_ready,
    output wire         o_keystream_available
);

  // **Parameters
  localparam STATE_START = 0;
  localparam STATE_KEYSTREAM_WAIT = 1;
  localparam STATE_KEYSTREAM_UNPACK = 2;


  // **Registers
  reg [2:0] r_state;

  reg          r_chacha20_req;
  reg  [511:0] r_keystream_512bit;
  reg  [ 31:0] r_keystream_32bit;
  reg  [ 31:0] r_chacha20_counter;
  reg  [  4:0] r_keystream_index;
  reg          r_keystream_valid;
  reg          r_chacha20_error;
  reg          r_keystream_available;

  assign o_chacha20_req = r_chacha20_req;
  assign o_chacha20_counter = r_chacha20_counter;
  //
  assign o_keystream_data = r_keystream_32bit;
  assign o_keystream_valid = r_keystream_valid;
  assign o_keystream_available = r_keystream_available;

  // ChaCha20 Keystream handler 256bit to 32bit intervals
  always @(posedge i_aclk or negedge i_aresetn) begin
    if (i_aresetn == 1'b0) begin
      r_chacha20_req <= 1'b0;
      r_keystream_512bit  <= 'd0;
      r_keystream_32bit   <= 'd0;
      r_chacha20_counter <= 'd0;
      r_keystream_index   <= 'd0;
      r_keystream_valid   <= 1'b0;
      r_keystream_available <= 1'b0;
    end else begin
      case(r_state)
        STATE_START: begin
          r_keystream_available <= 1'b0;
          if (i_enable & !i_chacha20_busy) begin
            // Request a new key
            r_chacha20_req <= 1'b1;
            r_keystream_index <= 'd0;
            r_state <= STATE_KEYSTREAM_WAIT;
          end
          // Reset the counter if the key is reloaded
          if (i_key_reload) begin
            r_chacha20_counter <= 'd0;
          end
        end
        STATE_KEYSTREAM_WAIT: begin
          // Wait for valid keystream
          r_chacha20_req <= 1'b0;
          if (i_chacha20_keystream_valid == 1'b1) begin
            r_keystream_512bit <= i_chacha20_keystream_data;
            //r_keystream_32bit <= i_chacha20_keystream_data[31:0];
            //r_keystream_valid <= 1'b1;
            //r_keystream_index <= r_keystream_index + 1;
            r_chacha20_error <= 1'b0;
            r_keystream_available <= 1'b1;
            r_state <= STATE_KEYSTREAM_UNPACK;
          end
          // error handling
          if (i_chacha20_busy == 1'b0 &&
              r_chacha20_req == 1'b0 && i_chacha20_keystream_valid == 1'b0) begin
            r_chacha20_error <= 1'b1;
            r_state <= STATE_START;
          end else begin
            r_chacha20_error <= 1'b0;
          end
        end
        STATE_KEYSTREAM_UNPACK: begin
          if (r_keystream_index < 5'd16) begin
            // NOTE: This syntax is not supported in older verilog
            if (i_keystream_ready) begin
              r_keystream_32bit <= r_keystream_512bit[r_keystream_index*32+:32];
              r_keystream_index <= r_keystream_index + 1;
              r_keystream_valid <= 1'b1;
            end
          end else begin
            r_state <= STATE_START;
            r_keystream_available <= 1'b0;
            r_chacha20_counter <= r_chacha20_counter + 1;
            r_keystream_valid <= 1'b0;
            r_keystream_index <= 'd0;
          end
        end
        default: r_state <= STATE_START;
      endcase
    end
  end

endmodule
