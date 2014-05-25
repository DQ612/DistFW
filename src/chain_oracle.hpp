// Author: Veeru Sadhanala (vsadhana@cs.cmu.edu)
// Date: 2014.04.25

#ifndef FW_CHAINORACLE_HPP
#define FW_CHAINORACLE_HPP

#include "abstract_svm_oracle.hpp"
#include <vector>

namespace fw {

class ChainOracle : public AbstractSVMOracle {
public:
  ChainOracle() { }

  std::vector<double> GenerateFeatureMap(const std::vector<double>& x,
      const std::vector<int>& y);

  double Loss(const std::vector<int>& y_truth,
      const std::vector<int>& y_predict);

  std::vector<double> MaxOracle(const std::vector<double>& w,
      const std::vector<double>& x_i,
      const std::vector<int>& y_i, int num_y_states);

private:
  std::vector<double> logDecode(
      const std::vector<double>& logNodePot, 
      const std::vector<double>& logEdgePot,
      const unsigned num_y_states,
      const unsigned num_nodes);
};

}
#endif
