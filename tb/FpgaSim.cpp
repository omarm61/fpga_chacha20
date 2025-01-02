#include <unistd.h>
#include <getopt.h>


#include <iostream>             // Need std::cout
#include <iomanip>
#include <string>
#include <ctype.h>
#include <iostream>
#include <fstream>

#include "../tb/FpgaSim.h"

//#include "Vtb_fpga.h"
//#include <verilated.h>          // Defines common routines
#include <verilated_vcd_c.h>

#define PERIOD  (5)
#define AXIS_TIMEOUT  (10000)

using namespace std;

CFpgaSim::CFpgaSim() : tfp(nullptr), ptop(nullptr), main_time(0)
{
	ptop = new Vtb_fpga;

  m_sAxiStreamRx.emplace(
    ptop->m_axis_fifo_rx_tready,
    ptop->m_axis_fifo_rx_tvalid,
    ptop->m_axis_fifo_rx_tdata
  );

  m_sAxiStreamEncrypt.emplace(
    ptop->m_axis_fifo_encrypt_tready,
    ptop->m_axis_fifo_encrypt_tvalid,
    ptop->m_axis_fifo_encrypt_tdata
  );
}

CFpgaSim::~CFpgaSim()
{
  if (tfp)
    tfp->close();

  ptop->final();               // Done simulating

  if (tfp)
    delete tfp;

  delete ptop;
}

void CFpgaSim::TraceDump(int lvl)
{
  // init trace dump
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  ptop->trace(tfp, lvl);
  tfp->open("wave.vcd");
}

/**
* Called by $time in Verilog
****************************************************************************/
double CFpgaSim::GetScTimestamp ()
{
  return main_time;       // converts to double, to match
                          // what SystemC does
}


/**
****************************************************************************/
void CFpgaSim::Tick(int count)
{
  for (;count > 0; --count)
  {
    //if (tfp)
    //tfp->dump(main_time); // dump traces (inputs stable before outputs change)
    ptop->eval();            // Evaluate model
    main_time++;            // Time passes...
    if (tfp)
      tfp->dump(main_time);   // inputs and outputs all updated at same time
  }
}


/**
****************************************************************************/
void CFpgaSim::Run(uint64_t limit)
{
  uint64_t count = 0;

  while(count < limit)
  {
    ptop->s_axi_aclk = 1;
    Tick(PERIOD);
    ptop->s_axi_aclk = 0;
    Tick(PERIOD);

    ++count;
  }
}

/** Reset FPGA
****************************************************************************/
void CFpgaSim::Reset()
{
	// this module has nothing to reset
    ptop->s_axi_aresetn = 0;
    Run(5);
    ptop->s_axi_aresetn = 1;
}


/**
****************************************************************************/
int CFpgaSim::WaitSignal(CData &sig, uint32_t val, uint32_t timeout)
{
  uint32_t count = 0;
  int ret = -1;

  while(count < timeout)
  {
    Run(1);
    if((uint32_t)sig == val) {
      ret = 0;
      break;
    }
    //if (count >= timeout) {
    //    ret = 1;
    //    break;
    //}
    ++count;
  }
  return ret;
}

/** Print Header
****************************************************************************/
void CFpgaSim::PrintHeader(string str)
{
    cout << endl << "====================================================" << endl;
    cout << str;
    cout << endl << "====================================================" << endl;
}

/** Testcase Header
****************************************************************************/
void CFpgaSim::PrintTestHeader(string str)
{
    cout << endl << "==============================================" << endl;
    cout << "\033[1;33mTestcase: \033[1;0m" << str;
    cout << endl << "==============================================" << endl;
}

/** Print simulation info
****************************************************************************/
void CFpgaSim::PrintInfo(string str)
{
    cout << main_time << "ns: " << str << endl;
}

/** Validate String data
****************************************************************************/
void CFpgaSim::ValidateString(std::string expected, std::string result, const std::string& str)
{
    if (expected == result)
    {
        cout << "\n------------------------------------------" << endl;
        cout << main_time << "ns: "<< "Test \033[1;32mPass\033[0m: " << str << endl;
        cout << "------------------------------------------\n" << endl;
    }
    else
    {
        cout << "\n------------------------------------------" << endl;
        cout << main_time << "ns: " << "Test \033[1;31mFail\033[0m: " << str << endl;
        cout << "   expected: "<< expected << endl;
        cout << "   result: "<< result << endl;
        cout << "------------------------------------------\n" << endl;
    }
}

/** Validate 32bit data
****************************************************************************/
void CFpgaSim::Validate32Bit(uint32_t expected, uint32_t result, const std::string& str)
{
    if (expected == result)
    {
        cout << "\n------------------------------------------" << endl;
        cout << main_time << "ns: "<< "Test \033[1;32mPass\033[0m: " << str << endl;
        cout << "------------------------------------------\n" << endl;
    }
    else
    {
        cout << "\n------------------------------------------" << endl;
        cout << main_time << "ns: " << "Test \033[1;31mFail\033[0m: " << str << endl;
        cout << "------------------------------------------\n" << endl;
    }
}



/** Validate 16bit data
****************************************************************************/
void CFpgaSim::Validate16Bit(uint16_t expected, uint16_t result, const std::string& str)
{
    if (expected == result)
    {
        cout << "\n------------------------------------------" << endl;
        cout << main_time << "ns: " << "Test \033[1;32mPass\033[0m: " << str << endl;
        cout << "------------------------------------------\n" << endl;
    }
    else
    {
        cout << "\n------------------------------------------" << endl;
        cout << main_time << "ns: " << "Test \033[1;31mFail\033[0m: " << str << endl;
        cout << "------------------------------------------\n" << endl;
    }
}

/** Validate flag
****************************************************************************/
void CFpgaSim::ValidateFlag(bool expected, bool result, const std::string& str)
{
    if (expected == result)
    {
        cout << "\n------------------------------------------" << endl;
        cout << main_time << "ns: " << "Test \033[1;32mPass\033[0m: " << str << endl;
        cout << "------------------------------------------\n" << endl;
    }
    else
    {
        cout << "\n------------------------------------------" << endl;
        cout << main_time << "ns: " << "Test \033[1;31mFail\033[0m: " << str << endl;
        cout << "------------------------------------------\n" << endl;
    }
}

/** Return Bit value within a register
****************************************************************************/
bool CFpgaSim::GetBit(uint32_t data, int index)
{
    uint32_t ret;
    ret = (data >> index) && 0x1;
    return (bool)ret;
}



/** AXI-Lite Read data
****************************************************************************/
uint32_t CFpgaSim::AxiRead(uint32_t addr)
{
    uint32_t ret = 0;
    Run(1);
    // Set valid address
    ptop->s_axi_araddr  = addr;
    ptop->s_axi_arvalid = 1;
    // Wait for device ready signal
    WaitSignal(ptop->s_axi_arready, 1, 100);
    ptop->s_axi_rready = 1;
    // Wait for data valid
    WaitSignal(ptop->s_axi_rvalid, 1, 100);
    Run(1);
    ptop->s_axi_rready = 0;
    ptop->s_axi_araddr  = 0;
    ptop->s_axi_arvalid = 0;
    // Capture data and reset signals
    ret = (uint32_t)ptop->s_axi_rdata;
    Run(1);

    return ret;
}

/** AXI-Lite Write data
****************************************************************************/
int CFpgaSim::AxiWrite(uint32_t addr, uint32_t data)
{
    int err = 0;

    Run(1);
    // Set valid address and  data
    ptop->s_axi_awaddr = addr;
    ptop->s_axi_wdata =  data;
    ptop->s_axi_awvalid = 1;
    ptop->s_axi_wstrb = 0xF; // All 4 bytes are valid
    // Wait for device ready signal
    err = WaitSignal(ptop->s_axi_awready, 1, 100);
    // Set data valid flag
    Run(1);
    ptop->s_axi_wvalid = 1;

    // Write Response
    // Wait write ready
    err = WaitSignal(ptop->s_axi_wready, 1, 100);
    Run(1);
    // Set repsonse flag
    ptop->s_axi_bready = 1;
    ptop->s_axi_wvalid = 0;
    // Wait for response bvalid
    err = WaitSignal(ptop->s_axi_bvalid, 1, 100);
    Run(1);
    // Reset signals
    ptop->s_axi_bready = 0;
    ptop->s_axi_awaddr = 0;
    ptop->s_axi_awvalid = 0;
    ptop->s_axi_wdata =  0;
    ptop->s_axi_wstrb = 0x0;
    Run(1);

    return err;
}

/** AXI-Lite Get Bit
****************************************************************************/
bool CFpgaSim::AxiGetBit(uint32_t offset, uint32_t index)
{
    uint32_t rdata = 0;
    bool flag = 0;

    rdata = AxiRead(offset);
    flag = GetBit(rdata, index);

    return flag;
}


/** AXI-Lite Write single bit
****************************************************************************/
int CFpgaSim::AxiSetBit(uint32_t offset, uint32_t index, bool flag)
{
    uint32_t rdata = 0;
    int ret = 0;

    rdata = AxiRead(offset);
    if (flag == 1)
    {
        rdata = rdata | (1 << index);
    } else {
        rdata = rdata & ~(1 << index);
    }
    // Write data
    ret = AxiWrite(offset, rdata);

    return ret;
}

/** Capture AXI Stream data
****************************************************************************/
//sTxData CFpgaSim::AxisTxCapture(int timeout)
//{
//    int count = 0;
//    int index = 0;
//
//    sTxData tx_data;
//
//    WaitSignal(ptop->m_axis_tvalid, 1, timeout);
//    for (index = 0; index <= 7; index++) {
//        tx_data.u32Sample[index*2] = ptop->m_axis_tdata;
//    }
//    return tx_data;
//}

/** Send Unencrypted message
****************************************************************************/
int CFpgaSim::WriteAxiStream(const std::string& strMsg)
{
  const int CHUNKSIZE = 4; // 4 bytes is the default so it can fit in a 32bit register
  uint32_t u32Msg = 0;

  // Split the string to 4 byte chunks and transmit over axi-stream
  for (size_t i = 0; i < strMsg.size(); i+=CHUNKSIZE) {
    // Wait for AXI-Stream to be ready
    // NOTE: This function advances the clock by 1cc so you don't need the Run(1) function before writing data
    if(WaitSignal(ptop->s_axis_tx_tready, 1, AXIS_TIMEOUT) == -1){
      // Transmission Failed
      return -1;
    }

    std::string strMsgChunk = strMsg.substr(i,CHUNKSIZE);
    char* cMsgByte = strMsgChunk.data();

    for (size_t i=0; i < 4; i++) {
      u32Msg = (u32Msg << 8) | static_cast<uint8_t>(*cMsgByte);
      cMsgByte++;
    }
    //Run(1);
    ptop->s_axis_tx_tdata = u32Msg;
    ptop->s_axis_tx_tvalid = 1;
  }
  Run(1);
  ptop->s_axis_tx_tvalid = 0;

  return 0;
}

/** Send Unencrypted message
****************************************************************************/
int CFpgaSim::WriteAxiStreamZeros(int iLength)
{

  // Split the string to 4 byte chunks and transmit over axi-stream
  for (size_t i = 0; i < iLength; i+=1) {
    // Wait for AXI-Stream to be ready
    // NOTE: This function advances the clock by 1cc so you don't need the Run(1) function before writing data
    if(WaitSignal(ptop->s_axis_tx_tready, 1, AXIS_TIMEOUT) == -1){
      // Transmission Failed
      return -1;
    }

    //Run(1);
    ptop->s_axis_tx_tdata = 0x0;
    ptop->s_axis_tx_tvalid = 1;
  }
  Run(1);
  ptop->s_axis_tx_tvalid = 0;

  return 0;
}


/** Receive Unencrypted message
****************************************************************************/
sAxiStreamData CFpgaSim::ReadAxiStream(sAxiStreamInterface& sAxi, int iLength)
{
    int count = 0;
    int index = 0;

    sAxiStreamData sData;
    sAxi.tready = 1;
    for (index = 0; index < iLength; index++) {
      if(WaitSignal(sAxi.tvalid, 1, AXIS_TIMEOUT) == 0){
        sData.u32Sample.push_back(sAxi.tdata);
      }
    }
    Run(1);
    sAxi.tready = 0;

    return sData;
}

/** Receive Unencrypted message as string
****************************************************************************/
std::string CFpgaSim::ReadAxiStreamString(sAxiStreamInterface& sAxi, int iLength)
{
    sAxiStreamData sData;
    string strRxData;
    union {
      uint32_t value;
      uint8_t  bytes[4];
    } uData;

    sData = ReadAxiStream(sAxi, iLength);
    
    for (int w = 0; w < iLength/4; w++) {
      uData.value = sData.u32Sample[w];
      std::reverse(uData.bytes, uData.bytes + 4);
      for (int i = 0; i < 4; i++) {
        strRxData += static_cast<char>(uData.bytes[i]);
      }
    }

    return strRxData;
}
