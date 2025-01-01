#ifndef TEST_PRBS_CIPHER_H
#define TEST_PRBS_CIPHER_H

class CTestPrbsCipher
{
    public:
        CTestPrbsCipher(CFpgaSim& thesim): sim(thesim) {};
        void ConfigureRx(uint32_t &seed);
        void ConfigureTx(uint32_t &seed);
        // Test Functions
        void TestHelloWorld();
        void TestKeyCorrelation(); 
        // Test Suite
        void RunTestSuite(uint32_t &seed); // Run multiple testcases
    private:
        CFpgaSim& sim;
};

#endif // TEST_PRBS_CIPHER_H
