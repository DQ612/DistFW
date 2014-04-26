#include "chain_oracle.hpp"
#include <string>
#include <algorithm>
#include <functional>

using namespace fw;
using namespace std;

Feature ChainOracle::GenerateFeatureMap(const Feature& x, const Feature& y){
    const size_t a = 26;           // a for size of alphabet
    const size_t p = x.size() / a; // p for number of pixels
    const size_t wl = y.size();    // wl for word length

    Feature phi(a*p + 2*a + a*a, 0);

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
    
    const size_t offset = a*p + 2*a;
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
    const size_t a = num_y_states;
    const size_t p = x_i.size() / a;
    const size_t wl = y_i.size();

    // unary (Line 30 in chain_oracle.m)
    // w[ 1:ap] -> w(p,a)
    // x_1 -> x(p,wl)
    // theta_unary = w' * x;
    vector<double> theta_unary(a*wl, 0);
    for(unsigned i=0; i<a; i++)
        for(unsigned j=0; j<wl; j++)
            theta_unary[i*a+j] = 
                std::inner_product(w.begin()+i*p, w.begin()+(i*p+p-1), 
                    x_i.begin()+j*p, 0);
    
    // bias
    std::transform(theta_unary.begin(), theta_unary.begin() + a,
            w.begin() + a*p, theta_unary.begin(),
            std::plus<double>() );
    std::transform(theta_unary.begin()+(wl-1)*p, theta_unary.end(),
            w.begin() + a*p, theta_unary.begin() + (wl-1)*p,
            std::plus<double>() );

    // pairs
    vector<double> theta_pair(w.begin() + a*p + 2*a, w.end());

    // add loss-augmentation to the score( normalized Hamming distance)
    for(Feature::iterator it=theta_unary.begin(); it != theta_unary.end(); it++)
        *it += 1.0/wl;
    for(unsigned j=0; j<wl; j++)
        theta_unary[ y_i[j] + j*a] -= 1.0/wl;

    return logDecode(theta_unary, theta_pair, a, wl);

}

Feature ChainOracle::logDecode(
    const vector<double>& logNodePot,   //(a,wl)
    const vector<double>& logEdgePot,   
    const unsigned num_y_states, 
    const unsigned num_nodes){

    typedef vector<double>::iterator Iter;
    
    const size_t a = num_y_states;
    const size_t wl = num_nodes;

    // Forward Pass
    vector<double> alpha(a*wl, 0); // (a,wl)
    std::copy(logNodePot.begin(), logNodePot.end(), alpha.begin());
    vector<double> tmp(a,0);

    vector<double> mxState(a*wl, 0); // (a,wl)

    for(size_t n=1; n<wl; n++){
        for(size_t i=0; i<a; i++){
            // tmp = alpha(:,n-1) + logEdgePot(:,i)
            // check if we are actually accessing logEdgePot's ith column
            transform(alpha.begin()+n*a, alpha.begin()+(n*a+a-1),
                    logEdgePot.begin()+i*a, tmp.begin(),
                    std::plus<double>() );

            Iter maxtmp = std::max_element(tmp.begin(), tmp.end());
            alpha[i+n*a] = logNodePot[i+n*a] + *maxtmp;
            mxState[i+n*a] = maxtmp - tmp.begin();
        }
    }

    // Backward Pass

    vector<double> y(wl, 0);
    Iter tmpmax = std::max_element(alpha.begin() + (wl-1)*a, alpha.end());
    y[wl-1] = (tmpmax - alpha.begin()) - (wl-1)*a;
    for(size_t n=wl-2; n >= 0; n--){
        y[n] = mxState[ y[n+1] + (n+1)*a];
    }

    return y;

}

