#ifndef TEST_CHACHA20_H
#define TEST_CHACHA20_H

class CTestChaCha20
{
    public:
        CTestChaCha20(CFpgaSim& thesim): sim(thesim) {};
        void ConfigureRx(uint32_t &seed);
        void ConfigureTx(uint32_t u32KeyArray[], uint32_t u32NonceArray[]);
        // Test Functions
        void TestHelloWorld();
        // Test Suite
        void RunTestSuite(uint32_t &seed); // Run multiple testcases
    private:
        CFpgaSim& sim;
};

#endif // TEST_PRBS_CIPHER_H
