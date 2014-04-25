#include <map>
#include <vector>

namespace fw {

// Sparse feature := (feature index --> feature value)
typedef std::map<int32_t, double> SpFeature;

// Dense feature.
typedef std::vector<double> Feature;

}   // namespace fw
