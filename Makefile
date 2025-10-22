COMPILER=verilator
VFLAGS=-Wall -Wno-fatal --timing --binary -j 0 --trace-fst --autoflush --assert -I./rtl -I./bench --prof-cfuncs -CFLAGS -DVL_DEBUG
SIM_ENGINE=vvp
WAVE_VIEWER=gtkwave

BUILD_DIR=obj_dir
MODULES_DIR=modules
TESTBENCHES_DIR=bench

TESTBENCHES=$(patsubst $(TESTBENCHES_DIR)/%_tb.sv,%,$(wildcard $(TESTBENCHES_DIR)/*_tb.sv))

define check_tb
	@if [ -z "$(TB)" ]; then \
		echo "Error: TB is not set. Please set TB to one of the following: $(TESTBENCHES)"; \
		exit 1; \
	elif ! echo "$(TESTBENCHES)" | grep -wq "$(TB)"; then \
		echo "Error: TB '$(TB)' is not a valid testbench. Please set TB to one of the following: $(TESTBENCHES)"; \
		exit 1; \
	fi
endef

define check_file_exists
	@if [ ! -f $(BUILD_DIR)/$(TB)_tb.$(1) ]; then \
		echo "Error: $(BUILD_DIR)/$(TB)_tb.$(1) not found. Ensure you have run 'make compile TB=$(TB)' first." ; \
		exit 1; \
	fi
endef

all:
	@for tb in $(TESTBENCHES); do \
		$(MAKE) compile TB=$$tb; \
	done

compile:
	$(call check_tb)
	mkdir -p $(BUILD_DIR)
	$(COMPILER) $(VFLAGS) $(TESTBENCHES_DIR)/$(TB)_tb.sv
	cd $(BUILD_DIR) && ./V$(TB)_tb

run:
	$(call check_tb)
	$(call check_file_exists,vvp)
	cd $(BUILD_DIR) && $(SIM_ENGINE) $(TB)_tb.vvp

wave: compile
	$(call check_tb)
	$(call check_file_exists,vcd)
	cd $(BUILD_DIR) && $(WAVE_VIEWER) $(TB)_tb.vcd

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all compile run wave clean
