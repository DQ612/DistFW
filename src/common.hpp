#ifndef FW_COMMON_HPP
#define FW_COMMON_HP

#include <map>
#include <vector>
#include <cstdint>
#include <memory>

namespace fw {

// Sparse feature := (feature index --> feature value)
typedef std::map<int32_t, double> SpFeature;

}   // namespace fw

#endif
