#ifndef TEST_PRBS_CIPHER_H
#define TEST_PRBS_CIPHER_H

class CTestPrbsCipher
{
    public:
        CTestPrbsCipher(CFpgaSim& thesim): sim(thesim) {};
        // Test Functions
        void key_correlation(); 
        // Test Suite
        void test_suite(); // Run multiple testcases
    private:
        CFpgaSim& sim;
};

#endif // TEST_PRBS_CIPHER_H
