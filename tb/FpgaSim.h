#ifndef FPGA_SIM_H
#define FPGA_SIM_H

#include <stdint.h>
#include "Vtb_fpga.h"

class VerilatedVcdC;
class Vtb_fpga;


// Encrypted Data Capture
struct sTxData{
    uint32_t u32Sample [16];  // [15:0]
};

class CFpgaSim
{
    private:
        CFpgaSim();
        ~CFpgaSim();
		VerilatedVcdC *tfp;
		Vtb_fpga *ptop;
		uint64_t main_time;
    public:
        static CFpgaSim& get_sim()
        {
            static CFpgaSim sim;
            return sim;
        }
        // Functions
        // Common simulation functions
        void TraceDump(int lvl);
        double GetScTimestamp ();
        void Tick(int count);
        void Run(uint64_t limit);
        void Reset();
        void PrintHeader(std::string str);
        void PrintInfo(std::string str);
        int  WaitSignal(CData &sig, uint32_t val, uint32_t timeout);
        void Validate32Bit(uint32_t expected, uint32_t result, std::string str);
        void Validate16Bit(uint16_t expected, uint16_t result, std::string str);
        void ValidateFlag(bool expected, bool result, std::string str);
        // bit operation
        bool GetBit(uint32_t data, int index);
        // AXI Interface
        uint32_t AxiRead(uint32_t addr);
        int  AxiWrite(uint32_t addr, uint32_t data);
        bool AxiGetBit(uint32_t offset, uint32_t index);
        int  AxiSetBit(uint32_t offset, uint32_t index, bool flag);
        // Transmitter Module
        sTxData  AxisTxCapture(int timeout);
};

#endif // FPGA_SIM_H
