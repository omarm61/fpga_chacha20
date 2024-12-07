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

using namespace std;


/**
****************************************************************************/
int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);

    int verbose = 0;
    int error = 0;
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
    // TC1: Read Command
    // --------------
    // Request a read
    m_Sim.AxiWrite(0x4, 0x1234); // Write PRBS seed 
    m_Sim.AxiWrite(0x0, 0x1); // Write Request


    // check if transaction was accepted
    rdata = m_Sim.AxiRead(0x4);
    m_Sim.Validate32Bit(0x1234, rdata, "Write PRBS Seed");


    // Run simulation 5000 clock cycles
    m_Sim.Run(20000);
    m_Sim.PrintHeader("Simulation Done");

	return 0;
}
