DISTFW_ROOT := $(shell readlink $(dir $(lastword $(MAKEFILE_LIST))) -f)
SRC_DIR = $(DISTFW_ROOT)/src

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
DISTFW_INCFLAGS = -I$(DISTFW_THIRD_PARTY_INCLUDE)
DISTFW_LDFLAGS = -Wl,-rpath,$(DISTFW_THIRD_PARTY_LIB) \
          -L$(DISTFW_THIRD_PARTY_LIB) \
          -pthread -lrt -lnsl -luuid \
          -lglog \
          -lgflags \
          -ltcmalloc

# defined in defns.mk
THIRD_PARTY = $(DISTFW_THIRD_PARTY)
THIRD_PARTY_SRC = $(DISTFW_THIRD_PARTY_SRC)
THIRD_PARTY_LIB = $(DISTFW_THIRD_PARTY_LIB)
THIRD_PARTY_INCLUDE = $(DISTFW_THIRD_PARTY_INCLUDE)

NEED_MKDIR = $(THIRD_PARTY_SRC) \
             $(THIRD_PARTY_LIB) \
             $(THIRD_PARTY_INCLUDE)

DISTFW_SRC = $(wildcard $(SRC_DIR)/*.cpp)
DISTFW_HDR = $(wildcard $(SRC_DIR)/*.hpp)
DISTFW_BIN = $(DISTFW_ROOT)/bin
DISTFW = $(DISTFW_BIN)/mf_main

svm_fw: $(DISTFW)

$(DISTFW): $(DISTFW_SRC)
	mkdir -p $(DISTFW_BIN)
	$(DISTFW_CXX) $(DISTFW_CXXFLAGS) $(DISTFW_INCFLAGS) $^ \
	$(DISTFW_LDFLAGS) -o $@

$(DISTFW_OBJ): %.o: %.cpp $(DISTFW_HDR)
	$(DISTFW_CXX) $(MSFT_CXXFLAGS) -I$(SRC_DIR) $(INCFLAGS) -c $< -o $@


all: path \
     third_party_core

path: $(NEED_MKDIR)

$(NEED_MKDIR):
	mkdir -p $@

clean:
	rm -rf $(DISTFW_BIN)

.PHONY: all path svm_fw clean

include $(THIRD_PARTY)/third_party.mk
