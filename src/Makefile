SVMFW_DIR := $(shell readlink $(dir $(lastword $(MAKEFILE_LIST))) -f)
DISTFW_ROOT = $(SVMFW_DIR)/../

include $(DISTFW_ROOT)/defns.mk

SVMFW_SRC = $(wildcard $(SVMFW_DIR)/*.cpp)
SVMFW_HDR = $(wildcard $(SVMFW_DIR)/*.hpp)
SVMFW_BIN = $(SVMFW_DIR)/bin
SVMFW = $(SVMFW_BIN)/fw_svm_main

fw_svm: $(SVMFW)

$(SVMFW): $(SVMFW_SRC) $(DISTFW_PS_LIB)
	mkdir -p $(SVMFW_BIN)
	$(DISTFW_CXX) $(DISTFW_CXXFLAGS) $(DISTFW_INCFLAGS) $^ \
	$(DISTFW_LDFLAGS) -o $@

$(SVMFW_OBJ): %.o: %.cpp $(SVMFW_HDR)
	$(CXX) $(CXXFLAGS) -I$(SVMFW_DIR) $(INCFLAGS) -c $< -o $@

clean:
	rm -rf $(SVMFW_BIN)

.PHONY: fw_svm clean

