#include "chain_oracle.hpp"
#include <iostream>

using namespace fw;
using namespace std;

void testOracleLoss(){
    ChainOracle oracle;
    std::vector<int> y_truth(5, 10 );
    std::vector<int> y_predict(5, 10 );
    y_predict[2] = 20; y_predict[3] = 30;

    double loss = oracle.Loss(y_truth, y_predict);

    std::cout << "Loss: " << loss << std::endl;
}
int main(){
    testOracleLoss();
}
