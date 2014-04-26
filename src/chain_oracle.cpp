#include "chain_oracle.hpp"
#include <string>
#include <algorithm>
#include <functional>

using namespace fw;
using namespace std;

Feature ChainOracle::GenerateFeatureMap(const Feature& x, const Feature& y){
    size_t a = 26;           // a for size of alphabet
    size_t p = x.size() / a; // p for number of pixels
    size_t wl = y.size();    // wl for word length

    Feature phi(0, a*p + 2*a + a*a);

    // for each letter in the word
    for( size_t i=0; i < wl; i++ ){
        // phi[ y[i]*p : (y[i]+1)*p -1] += x[i*p: i*p+p-1]
        std::transform( 
                x.begin() + i*p,  x.begin() + (i*p+p-1),
                phi.begin() + y[i]*p,
                phi.begin() + y[i]*p, // output
                std::plus<double>() );
    }

    // bias for the first and last letters
    phi[ a*p + y.front() ] = 1;    
    phi[ a*p + y.back() ] = 1;

    // pairwise
    
    size_t offset = a*p + 2*a;
    for( size_t i=0; i < wl-1; i++ ){
        size_t idx = y[i] + a*y[i+1];
        phi[ offset + idx ] += 1;
    }

    return phi;
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

}
