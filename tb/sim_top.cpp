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

#define TX_AXI_OFFSET     0x0
#define TX_AXI_CONTROL    TX_AXI_OFFSET+0x0
#define TX_AXI_PRBS_SEED  TX_AXI_OFFSET+0x4

#define RX_AXI_OFFSET     0x10000000
#define RX_AXI_CONTROL    RX_AXI_OFFSET+0x0
#define RX_AXI_PRBS_SEED  RX_AXI_OFFSET+0x4

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

    unsigned seed;

    // Generate a random seed value
    read(open("/dev/urandom", O_RDONLY), &seed, sizeof(seed));
    printf("\nRANDOM SEED VALUE: 0x%0x\n", seed);
    srand(seed);

    CFpgaSim& m_Sim = CFpgaSim::get_sim();

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

    // --------------
    // Configure TX
    // --------------
    // Write SEED and enable module
    m_Sim.AxiWrite(TX_AXI_PRBS_SEED, 0x1234); // Write PRBS seed 
    m_Sim.AxiWrite(TX_AXI_CONTROL, 0x2); // Load SEED 
    m_Sim.AxiWrite(TX_AXI_CONTROL, 0x1); // Write Request
    // check if transaction was accepted
    rdata = m_Sim.AxiRead(TX_AXI_PRBS_SEED);
    m_Sim.Validate32Bit(0x1234, rdata, "Configure TX");

    // --------------
    // Configure RX
    // --------------
    // Write SEED and enable module
    m_Sim.AxiWrite(RX_AXI_PRBS_SEED, 0x1234); // Write PRBS seed 
    m_Sim.AxiWrite(RX_AXI_CONTROL, 0x2); // Load SEED 
    m_Sim.AxiWrite(RX_AXI_CONTROL, 0x1); // Write Request
    // check if transaction was accepted
    rdata = m_Sim.AxiRead(RX_AXI_PRBS_SEED);
    m_Sim.Validate32Bit(0x1234, rdata, "Configure RX");

    // Transmit data
    std::string txMsg = "Hello World!";
    printf("-->> Tx Message: %s \n", txMsg.c_str());
    ret = m_Sim.SendData(txMsg, 10000);
    m_Sim.ValidateFlag(0, ret, "Sending Message..");

    // Receive encrypted data
    std::string rxMsg = m_Sim.ReadRxFifoString(txMsg.length(), 10000);
    printf("-->> Rx Message: %s \n", rxMsg.c_str());

    m_Sim.ValidateString(txMsg, rxMsg, "Tx/Rx match");




    // Run simulation 5000 clock cycles
    m_Sim.Run(20000);
    m_Sim.PrintHeader("Simulation Done");

	return 0;
}
