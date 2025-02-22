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
#include <fcntl.h>

#include "Vtb_fpga.h"
#include "../../tb/FpgaSim.h"
#include "../../tb/testcases/TestPrbsCipher.h"
#include "../../tb/testcases/TestChaCha20.h"


using namespace std;


/**
****************************************************************************/
int main(int argc, char** argv)
{
  Verilated::commandArgs(argc, argv);

  int verbose = 0;
  int ret = 0;
  int timeout_counter = 0;
  uint32_t wdata = 0;
  uint32_t rdata = 0;

  uint32_t seed = 0;

  // Generate a random seed value
  read(open("/dev/urandom", O_RDONLY), &seed, sizeof(seed));
  printf("\nRANDOM SEED VALUE: 0x%0x\n", seed);
  srand(seed);

  CFpgaSim& m_Sim = CFpgaSim::get_sim();

  // Initiate test suites 
  CTestPrbsCipher   m_TestPrbsCipher(m_Sim);
  CTestChaCha20   m_TestChaCha20(m_Sim);

  int opt;
  while ((opt = getopt(argc, argv, "tv:")) != -1)
  {
    switch (opt)
    {
      case 'v':
        verbose=atoi(optarg);
        break;
      case 't':
        m_Sim.TraceDump(99);
        break;
    }
  }

  //// start things going
  m_Sim.PrintHeader("Simulation Start");
  //// Reset Module
  m_Sim.Reset();
  m_Sim.PrintInfo("Reset module");
  m_Sim.Run(10);



  // PRBS Test Suite
  m_TestPrbsCipher.RunTestSuite(seed);
  // ChaCha20
  m_TestChaCha20.RunTestSuite(seed);



  // Run simulation 5000 clock cycles
  m_Sim.Run(20000);
  m_Sim.PrintHeader("Simulation Done");

  return 0;
}
