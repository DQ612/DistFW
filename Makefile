# Assuming this Makefile lives in project root directory
PROJECT := $(shell readlink $(dir $(lastword $(MAKEFILE_LIST))) -f)

DISTFW_ROOT = $(PROJECT)

include $(PROJECT)/defns.mk

# defined in defns.mk
THIRD_PARTY = $(DISTFW_THIRD_PARTY)
THIRD_PARTY_SRC = $(DISTFW_THIRD_PARTY_SRC)
THIRD_PARTY_LIB = $(DISTFW_THIRD_PARTY_LIB)
THIRD_PARTY_INCLUDE = $(DISTFW_THIRD_PARTY_INCLUDE)

NEED_MKDIR = $(THIRD_PARTY_SRC) \
             $(THIRD_PARTY_LIB) \
             $(THIRD_PARTY_INCLUDE)

all: path \
     third_party_core

path: $(NEED_MKDIR)

$(NEED_MKDIR):
	mkdir -p $@

clean:
	rm -rf $(BIN) $(LIB) $(PS_OBJ)

.PHONY: all path clean

include $(THIRD_PARTY)/third_party.mk
