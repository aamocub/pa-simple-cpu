SHELL := /bin/bash
SIM := verilator
SIM_ARGS ?= --quiet \
	    --report-unoptflat \
	    -Wall -Wno-fatal \
	    --timing \
	    --binary \
	    -j 0 \
	    --trace-fst \
	    --trace-structs \
	    --autoflush \
	    --assert \
	    -I./rtl \
	    -I./bench \
	    -CFLAGS \
	    -DVL_DEBUG \
	    -Wno-UNUSEDPARAM \
	    -Wno-UNUSEDSIGNAL
WAVE_VIEWER := surfer

BUILDDIR := obj_dir
TBDIR := bench
TBLIST = $(patsubst $(TBDIR)/%_tb.sv,%,$(wildcard $(TBDIR)/*_tb.sv))
TESTDIR := tests
TESTLIST = $(patsubst $(TESTDIR)/rv32ui-p-%.hex,%,$(wildcard $(TESTDIR)/rv32ui-p-*))

define check_tb
	@if [[ -z "$(TB)" ]]; \
	then \
		echo "Error: TB is not set. Please set TB to one of the following: $(TBLIST)"; \
	elif ! echo "$(TBLIST)" | grep -wq "$(TB)"; then \
		echo "Error: TB '$(TB)' is not a valid testbench. Please set TB to one of the following: $(TBLIST)"; \
		exit 1; \
	fi
endef

define check_tests
	@if [[ -z "$(TEST)" ]]; \
	then \
		echo "Error: TEST is not set. Please set TEST to one of the following: $(TESTLIST)"; \
	elif ! echo "$(TESTLIST)" | grep -wq "$(TEST)"; then \
		echo "Error: TEST '$(TEST)' is not a valid testbench. Please set TEST to one of the following: $(TESTLIST)"; \
		exit 1; \
	fi
endef

define check_file_exists
	@if [[ ! -f $(BUILDDIR)/$(TB)_tb.$(1) ]] \
	then \
		echo "Error: $(BUILDDIR)/$(TB)_tb.$(1) not found. Ensure you have run 'make compile TB=$(TB)' first." ; \
		exit 1; \
	fi
endef

MAKEFLAGS ?= --no-print-directory --silent

all:
	@for tb in $(TBLIST); do \
		$(MAKE) compile TB=$$tb
	done

compile:
	$(call check_tb)
	@mkdir -p $(BUILDDIR)
	@$(SIM) $(SIM_ARGS) $(TBDIR)/$(TB)_tb.sv

run: compile
	$(call check_tb)
	$(call check_file_exists,)
	@cd $(BUILDDIR) && ./V$(TB)_tb +verilator+quiet

wave: run
	$(call check_tb)
	$(call check_file_exists,fst)
	@cd $(BUILDDIR) && >/dev/null $(WAVE_VIEWER) $(TB)_tb.fst &
	
test-all:
	@for f in $(TESTLIST); do \
		printf "\tTESTING %s\n" $$f ; \
		TB=top TEST=$$f $(MAKE) --no-print-directory --silent test ; \
	done
	
test: compile
	$(call check_tests)
	@cd $(BUILDDIR) && ./V$(TB)_tb +verilator+quiet +load=$(PWD)/$(TESTDIR)/rv32ui-p-$(TEST).hex

test-wave: test
	@cd $(BUILDDIR) && >/dev/null $(WAVE_VIEWER) $(TB)_tb.fst

clean:
	rm -rf $(BUILDDIR)

.PHONY: all compile run wave clean test test-all