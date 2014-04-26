#include "chain_oracle.hpp"
#include <string>

using namespace fw;
using namespace std;

SpFeature ChainOracle::GenerateFeatureMap(const Feature& x, const Feature& y){
    return SpFeature();
}

double ChainOracle::Loss(const Feature& y_truth, const Feature& y_predict){
	
	double loss = 0;
	Feature::const_iterator t = y_truth.begin();
	Feature::const_iterator p = y_predict.begin();
	for(; t != y_truth.end(); t++, p++ ){
		if( *t != *p )
			loss += 1;
	}
	return loss / y_truth.size();
}

Feature ChainOracle::MaxOracle(const Feature& w, const Feature& x_i,
        const Feature& y_i, int num_y_states){
    throw std::string("MaxOracle not implemented");
}
