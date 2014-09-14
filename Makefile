DCC=gdc
DFLAGS=
LIBS=-lncurses
SRCDIR=src
OBJDIR=obj
SRC=$(shell find $(SRCDIR) -name '*.d')
OBJ=$(SRC:**/%.d=$(OBJDIR)/%.o)
OUT=bin/quiver

.PHONY: all debug clean

all: debug
    
debug: DFLAGS += -g

debug: $(OUT)

$(OUT): $(OBJ)
		mkdir -p bin
		$(DCC) $(DFLAGS) -o $@ $(OBJ) $(LIBS)

$(OBJDIR)/%.o : $(SRCDIR)/%.d
	$(DCC) $(DFLAGS) -c $<

clean: 
	rm -f $(OUT)

