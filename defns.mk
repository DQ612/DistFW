# Requires DISTFW_ROOT to be defined

DISTFW_SRC = $(DISTFW_ROOT)/src
DISTFW_LIB = $(DISTFW_ROOT)/lib
DISTFW_THIRD_PARTY = $(DISTFW_ROOT)/third_party
DISTFW_THIRD_PARTY_SRC = $(DISTFW_THIRD_PARTY)/src
DISTFW_THIRD_PARTY_INCLUDE = $(DISTFW_THIRD_PARTY)/include
DISTFW_THIRD_PARTY_LIB = $(DISTFW_THIRD_PARTY)/lib

DISTFW_CXX = g++
DISTFW_CXXFLAGS = -g -O3 \
           -std=c++0x \
           -Wall \
					 -Wno-sign-compare \
           -fno-builtin-malloc \
           -fno-builtin-calloc \
           -fno-builtin-realloc \
           -fno-builtin-free \
           -fno-omit-frame-pointer
DISTFW_INCFLAGS = -I$(DISTFW_SRC) -I$(DISTFW_THIRD_PARTY_INCLUDE)
DISTFW_LDFLAGS = -Wl,-rpath,$(DISTFW_THIRD_PARTY_LIB) \
          -L$(DISTFW_THIRD_PARTY_LIB) \
          -pthread -lrt -lnsl -luuid \
          -lglog \
          -lgflags \
          -ltcmalloc
