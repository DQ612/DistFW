#ifndef FW_COMMON_HPP
#define FW_COMMON_HP

#include <map>
#include <vector>
#include <cstdint>

namespace fw {

// Sparse feature := (feature index --> feature value)
typedef std::map<int32_t, double> SpFeature;

// Dense feature.
typedef std::vector<double> Feature;

}   // namespace fw

#endif
