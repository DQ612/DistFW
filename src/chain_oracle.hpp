// Author: Veeru Sadhanala (vsadhana@cs.cmu.edu)
// Date: 2014.04.25

#ifndef FW_CHAINORACLE_HPP
#define FW_CHAINORACLE_HPP

#include "abstract_svm_oracle.hpp"

namespace fw {

class ChainOracle : public AbstractSVMOracle {
    public:
        Feature GenerateFeatureMap(const Feature& x, const Feature& y);

        double Loss(const Feature& y_truth, const Feature& y_predict);

        Feature MaxOracle(const Feature& w, const Feature& x_i,
                const Feature& y_i, int num_y_states);

        ChainOracle(){}

};

}
#endif
