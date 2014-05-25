// Author: Dai Wei (wdai@cs.cmu.edu)
// Date: 2014.04.25

#include "common.hpp"
#include <vector>

namespace fw {


class AbstractSVMOracle {
public:
  // Compute the feature map \phi based on dense
  // data feature x and the associated label y.
  virtual std::vector<double> GenerateFeatureMap(const std::vector<double>& x,
      const std::vector<int>& y) = 0;

  // Compute structural loss between the true and predicted labels.
  virtual double Loss(const std::vector<int>& y_truth,
      const std::vector<int>& y_predict) = 0;

  // Solve eq. (2) in "Stochastic Block-Coordinate Frank-Wolfe Optimization for
  // Structural SVMs".
  //
  // Comment(wdai): Currently we assume that each y has 'num_y_states' possible
  // states and they range from 0 to (num_y_states - 1).
  virtual std::vector<double> MaxOracle(const std::vector<double>& w,
      const std::vector<double>& x_i, const std::vector<int>& y_i,
      int num_y_states) = 0;
};

}  // namespace
