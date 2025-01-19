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
#include "../../tb/testcases/TestPrbsCipher.h"

using namespace std;

/** Configure Tx
****************************************************************************/
void CTestPrbsCipher::ConfigureTx(uint32_t &seed)
{
  uint32_t rdata = 0;
  // --------------
  // Configure TX
  // --------------
  // Write SEED and enable module
  sim.AxiWrite(TX_AXI_PRBS_SEED_OFFSET, seed); // Write PRBS seed 
  sim.AxiSetBit(TX_AXI_CONTROL_OFFSET, TX_CONTROL_ENCRYPT_TYPE_INDEX, 0); // Enable PRBS
  sim.AxiSetBit(TX_AXI_CONTROL_OFFSET, TX_CONTROL_KEY_RELOAD_INDEX, 1); // Load Key
  sim.AxiSetBit(TX_AXI_CONTROL_OFFSET, TX_CONTROL_ENABLE_INDEX, 1); // Write Request
  // check if transaction was accepted
  rdata = sim.AxiRead(TX_AXI_PRBS_SEED_OFFSET);
  sim.Validate32Bit(seed, rdata, "Configure TX");
}

void CTestPrbsCipher::DisableTx()
{
  sim.AxiSetBit(TX_AXI_CONTROL_OFFSET, TX_CONTROL_ENABLE_INDEX, 0);
}

/** Configure Rx
****************************************************************************/
void CTestPrbsCipher::ConfigureRx(uint32_t &seed)
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

void CTestPrbsCipher::DisableRx()
{
  sim.AxiWrite(RX_AXI_CONTROL_OFFSET, 0x0); // Disable RX
}


/** Hello World Test
****************************************************************************/
void CTestPrbsCipher::TestHelloWorld()
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


/** Calculate key Correlation
****************************************************************************/
void CTestPrbsCipher::TestKeyCorrelation()
{
  sAxiStreamData sData;
  std::vector<int> x(256);

  sim.PrintInfo("--Key Correlation");
  // Send a constant message
  // Write a stream of zeros, length 256 words
  sim.WriteAxiStreamZeros(256);
  sData = sim.ReadAxiStream(sim.m_sAxiStreamEncrypt.value(), 256);
  iota(x.begin(), x.end(), 1);

  printf("Data Length: %0d\n", size(sData.u32Sample));
  for (size_t i=0; i < 10; i++) {
    printf("idx: %0d, Data: %0u, x: %u\n", i, sData.u32Sample[i], x[i]);
  }

  // Capture the ciphered key stream

  // Calculate correlation
}

/** Run Test Suite
****************************************************************************/
void CTestPrbsCipher::RunTestSuite(uint32_t &seed)
{
  // Header
  sim.PrintTestHeader("PRBS Cipher: Start");

  // Configure Modules
  ConfigureTx(seed);
  ConfigureRx(seed);


  // Run Test Cases
  TestHelloWorld();
  //TestKeyCorrelation();

  // Disable TX and RX
  DisableRx();
  DisableTx();

  // Header
  //sim.PrintTestHeader("PRBS Cipher: Done");
  cout << endl << endl;
}
