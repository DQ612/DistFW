// Author: Dai Wei (wdai@cs.cmu.edu)
// Date: 2014.04.25

#include "svm_oracle/abstract_svm_oracle.hpp"
#include "context.hpp"
#include <memory>

namespace fw {

// This implements algorithm 4 in (Lacoste-Julien, Jaggi, Schmidt, Pletscher;
// ICML 2013). For distributedFW this is the solver on each machine / thread.
class BCFWSolver {
public:
  BCFWSolver();

private:

  std::unique_ptr<AbstractSVMOracle> oracle_;

  double lambda_;
};

}  // namespace fw
