#include <unistd.h>
#include <getopt.h>

#include <verilated.h>          // Defines common routines
#include <verilated_vcd_c.h>
#include <iostream>             // Need std::cout
#include <iomanip>
#include <string>
#include <ctype.h>
#include <iostream>
#include <fstream>
#include <numeric>
#include <vector>

#include "Vtb_fpga.h"
#include "../../tb/FpgaSim.h"
#include "../../tb/testcases/TestChaCha20.h"

using namespace std;

/** Configure Tx
****************************************************************************/
void CTestChaCha20::ConfigureTx(uint32_t u32KeyArray[], uint32_t u32NonceArray[])
{
  uint32_t rdata = 0;
  // --------------
  // Configure TX
  // --------------
  // Load Key
  for (size_t i = 0; i < 8; i++) {
    sim.AxiWrite(TX_AXI_CHACHA20_KEY1_OFFSET + (0x4*i), u32KeyArray[i]);
  }
  // Load Nonce
  for (size_t i = 0; i < 3; i++) {
    sim.AxiWrite(TX_AXI_CHACHA20_NONCE1_OFFSET + (0x4*i), u32NonceArray[i]);
  }
  sim.AxiSetBit(TX_AXI_CONTROL_OFFSET, TX_CONTROL_ENCRYPT_TYPE_INDEX, 1); // Enable ChaCha20 keystream
  sim.AxiSetBit(TX_AXI_CONTROL_OFFSET, TX_CONTROL_KEY_RELOAD_INDEX, 1); // Load Key
  sim.AxiSetBit(TX_AXI_CONTROL_OFFSET, TX_CONTROL_ENABLE_INDEX, 1); // Write Request
  // check if transaction was accepted
  rdata = sim.AxiRead(TX_AXI_PRBS_SEED_OFFSET);
}

/** Configure Rx
****************************************************************************/
void CTestChaCha20::ConfigureRx(uint32_t &seed)
{
  uint32_t rdata = 0;
  // --------------
  // Configure RX
  // --------------
  // Write SEED and enable module
  sim.AxiWrite(RX_AXI_PRBS_SEED_OFFSET, seed); // Write PRBS seed 
  sim.AxiWrite(RX_AXI_CONTROL_OFFSET, 0x2); // Load SEED 
  sim.AxiWrite(RX_AXI_CONTROL_OFFSET, 0x1); // Write Request
  // check if transaction was accepted
  rdata = sim.AxiRead(RX_AXI_PRBS_SEED_OFFSET);
  sim.Validate32Bit(seed, rdata, "Configure RX");
}

/** Hello World Test
****************************************************************************/
void CTestChaCha20::TestHelloWorld()
{
  // Transmit data
  std::string txMsg = "Hello World!";
  printf("-->> Tx Message: %s \n", txMsg.c_str());
  sim.WriteAxiStream(txMsg);

  // Read Encrypted data
  std::string encryptMsg = sim.ReadAxiStreamString(sim.m_sAxiStreamEncrypt.value(), txMsg.length());
  printf("-->> Encrypted Message: %s \n", encryptMsg.c_str());

  // Read Received data
  std::string rxMsg = sim.ReadAxiStreamString(sim.m_sAxiStreamRx.value(), txMsg.length());
  printf("-->> Rx Message: %s \n", rxMsg.c_str());

  sim.ValidateString(txMsg, rxMsg, "PRBS Encryption: Hello World!");
}


/** Run Test Suite
****************************************************************************/
void CTestChaCha20::RunTestSuite(uint32_t &seed)
{
  uint32_t u32KeyArray[8] = {1,2,3,4,5,6,7,8};
  uint32_t u32NonceArray[3] = {9,10,11};

  // Header
  sim.PrintTestHeader("ChaCha20: Start");

  // Configure Modules
  ConfigureTx(u32KeyArray, u32NonceArray);


  // Header
  //sim.PrintTestHeader("ChaCha20: Done");
  cout << endl << endl;
}
