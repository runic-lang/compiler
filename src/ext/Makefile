LLVM_CONFIG ?= $(shell command -v llvm-config-5.0 || command -v llvm-config)
CXXFLAGS += $(shell $(LLVM_CONFIG) --cxxflags)

.PHONY: clean

all: llvm/di_builder.o

%.o: %.cc
	$(CXX) -c $(CXXFLAGS) -o $@ $<

clean:
	rm -f llvm/*.o
