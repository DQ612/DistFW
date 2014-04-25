// Author: Dai Wei (wdai@cs.cmu.edu)
// Date: 2014.04.25

#include "common.hpp"

namespace fw {


class AbstractSVMOracle {
public:
  // Compute the feature map \phi in sparse format (SpFeature) based on dense
  // data feature x and the associated label y.
  SpFeature GenerateFeatureMap(const Feature& x, const Feature& y) = 0;

  // Compute structural loss between the true and predicted labels.
  double Loss(const Feature& y_truth, const Feature& y_predict) = 0;

  // Solve eq. (2) in "Stochastic Block-Coordinate Frank-Wolfe Optimization for
  // Structural SVMs".
  //
  // Comment(wdai): Currently we assume that each y has 'num_y_states' possible
  // states and they range from 0 to (num_y_states - 1).
  Feature MaxOracle(const Feature& w, const Feature& x_i,
      const Feature& y_i, int num_y_states) = 0;
};

}  // namespace
