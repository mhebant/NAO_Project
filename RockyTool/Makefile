

TYPE=exec# shared, static or exec
BUILD=debug# debug or release
EXEC=rockytool
CXXFLAGS=-Wall -std=c++11
CXXFLAGS_debug=-g
CXXFLAGS_release=-s -O2
LDFLAGS=
LDFLAGS_debug=
LDFLAGS_release=
INCLUDES=

srcdir=./src
hdir=./include
objdir=./obj
resdir=./res
bindir=./bin
CXX=g++
AR=ar

CXXFLAGS+= $(CXXFLAGS_$(BUILD)) -I$(hdir) $(INCLUDES)
ifeq ($(TYPE),shared)
	CXXFLAGS+= -fPIC
endif
LDFLAGS+= $(LDFLAGS_$(BUILD))
SRC=$(wildcard $(srcdir)/*.cpp)
RES=$(wildcard $(resdir)/*)
OBJ=$(addprefix $(objdir)/,$(notdir $(SRC:.cpp=.o))) $(addprefix $(objdir)/,$(notdir $(addsuffix .o,$(RES))))

all: dependences $(bindir)/$(EXEC) 
	@echo "$(EXEC) built ($(TYPE) $(BUILD))"

$(bindir)/$(EXEC): $(OBJ)
ifeq ($(TYPE),static)
	@$(AR) -q $(bindir)/lib$(EXEC).a $^
endif
ifeq ($(TYPE),exec)
	@$(CXX) -o $(bindir)/$(EXEC) $^ $(LDFLAGS)
endif
ifeq ($(TYPE),shared)
	@$(CXX) -shared -fPIC -o $(bindir)/lib$(EXEC).so $^ $(LDFLAGS)
endif

$(resdir)/frankmbr: $(srcdir)/frankmbr.asm
	@nasm -o $@ $<

$(objdir)/%.o: $(srcdir)/%.cpp
	@$(CXX) -c $(CXXFLAGS) -o $@ $<
	@echo "$@ generated"

$(objdir)/%.o: $(resdir)/%
	@echo SECTION .data > $<.resasm
	@echo GLOBAL _bin_$(basename $(notdir $<))_beg >> $<.resasm
	@echo _bin_$(basename $(notdir $<))_beg: >> $<.resasm
	@echo INCBIN '"$<"' >> $<.resasm
	@echo GLOBAL _bin_$(basename $(notdir $<))_end >> $<.resasm
	@echo _bin_$(basename $(notdir $<))_end: >> $<.resasm
	@nasm -f elf64 -o $@ $<.resasm
	#@rm -rf $<.resasm

.PHONY: dependences clean mrproper

dependences:
	@$(CXX) -M -MF dependences $(CXXFLAGS) $(SRC)

clean:
	@rm -rf $(objdir)/*.o
	@rm -rf $(resdir)/*.resasm
	@rm -rf dependences

mrproper: clean
	@rm -rf $(bindir)/$(EXEC)

-include dependences
