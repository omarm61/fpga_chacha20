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

#include "Vtb_fpga.h"
#include "../../tb/FpgaSim.h"
#include "../../tb/testcases/TestPrbsCipher.h"

using namespace std;

/** Calculate key Correlation
****************************************************************************/
void CTestPrbsCipher::key_correlation()
{
  sim.PrintInfo("--Key Correlation");
  // Send a constant message

  // Capture the ciphered key stream

  // Calculate correlation
}

/** Run Test Suite
****************************************************************************/
void CTestPrbsCipher::test_suite()
{
    // Header
    sim.PrintTestHeader("Prbs Cipher: Start");

    // Dummy Register 0
    key_correlation();

    // Header
    sim.PrintTestHeader("Prbs Cipher: Done");
}
