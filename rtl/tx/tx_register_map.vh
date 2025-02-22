// Control Register
`define S_AXI_REG_CONTROL_OFFSET               32'h0
`define S_AXI_REG_CONTROL_TX_ENABLE_INDEX      0
`define S_AXI_REG_CONTROL_KEY_RELOAD_INDEX     1

// PRBS Seed
`define S_AXI_REG_PRBS_SEED_OFFSET             32'h4
`define S_AXI_REG_PRBS_SEED_INDEX              31:0

// Status
`define S_AXI_REG_STATUS_OFFSET                32'h8
`define S_AXI_REG_STATUS_CHACHA20_ERROR_INDEX  0
`define S_AXI_REG_STATUS_ID_INDEX              31:16 // 0xDEAD

// ChaCha20 block counter
`define S_AXI_REG_CHACHAC20_COUNTER_OFFSET     32'hC

// ChaCha20 Key
`define S_AXI_REG_CHACHAC20_KEY_1_OFFSET       32'h10
`define S_AXI_REG_CHACHAC20_KEY_2_OFFSET       32'h14
`define S_AXI_REG_CHACHAC20_KEY_3_OFFSET       32'h18
`define S_AXI_REG_CHACHAC20_KEY_4_OFFSET       32'h1C
`define S_AXI_REG_CHACHAC20_KEY_5_OFFSET       32'h20
`define S_AXI_REG_CHACHAC20_KEY_6_OFFSET       32'h24
`define S_AXI_REG_CHACHAC20_KEY_7_OFFSET       32'h28
`define S_AXI_REG_CHACHAC20_KEY_8_OFFSET       32'h2C

// ChaCha20 Nonce
`define S_AXI_REG_CHACHAC20_NONCE_1_OFFSET     32'h30
`define S_AXI_REG_CHACHAC20_NONCE_2_OFFSET     32'h34
`define S_AXI_REG_CHACHAC20_NONCE_3_OFFSET     32'h38
