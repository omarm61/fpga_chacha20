#ifndef FPGA_REGISTER_MAP_H
#define FPGA_REGISTER_MAP_H

// Register Map

// TX Registers
// -----------------
#define TX_AXI_OFFSET               0x0
#define TX_AXI_CONTROL_OFFSET       TX_AXI_OFFSET+0x0
//
#define TX_CONTROL_ENABLE_INDEX         0
#define TX_CONTROL_KEY_RELOAD_INDEX     1
#define TX_CONTROL_ENCRYPT_TYPE_INDEX   2
//
#define TX_AXI_PRBS_SEED_OFFSET            TX_AXI_OFFSET+0x4
#define TX_AXI_STATUS_OFFSET               TX_AXI_OFFSET+0x8
#define TX_AXI_CHACHA20_COUNTER_OFFSET     TX_AXI_OFFSET+0xC
// Key
#define TX_AXI_CHACHA20_KEY1_OFFSET        TX_AXI_OFFSET+0x10
#define TX_AXI_CHACHA20_KEY2_OFFSET        TX_AXI_OFFSET+0x14
#define TX_AXI_CHACHA20_KEY3_OFFSET        TX_AXI_OFFSET+0x18
#define TX_AXI_CHACHA20_KEY4_OFFSET        TX_AXI_OFFSET+0x1C
#define TX_AXI_CHACHA20_KEY5_OFFSET        TX_AXI_OFFSET+0x20
#define TX_AXI_CHACHA20_KEY6_OFFSET        TX_AXI_OFFSET+0x24
#define TX_AXI_CHACHA20_KEY7_OFFSET        TX_AXI_OFFSET+0x28
#define TX_AXI_CHACHA20_KEY8_OFFSET        TX_AXI_OFFSET+0x2C
// Nonce
#define TX_AXI_CHACHA20_NONCE1_OFFSET      TX_AXI_OFFSET+0x30
#define TX_AXI_CHACHA20_NONCE2_OFFSET      TX_AXI_OFFSET+0x34
#define TX_AXI_CHACHA20_NONCE3_OFFSET      TX_AXI_OFFSET+0x38

// RX Registers
// -----------------
#define RX_AXI_OFFSET                       0x10000000
#define RX_AXI_CONTROL_OFFSET               RX_AXI_OFFSET+0x0
#define RX_AXI_PRBS_SEED_OFFSET             RX_AXI_OFFSET+0x4

#endif
