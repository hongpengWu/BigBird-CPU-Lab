CPU_DIR ?= mySoC
SOC_DIR ?= mySoC
COMMON_SOC = $(SOC_DIR)/miniRV_SoC.v $(SOC_DIR)/dram_driver.sv
CPU_VSRC = $(wildcard $(CPU_DIR)/*.sv $(CPU_DIR)/*.v)
VSRC = $(wildcard vsrc/ram.v) $(COMMON_SOC) $(filter-out $(COMMON_SOC),$(CPU_VSRC))
CSRC = $(wildcard golden_model/*.c) $(wildcard golden_model/stage/*.c) $(wildcard golden_model/peripheral/*.c) $(wildcard csrc/*.c csrc/*.cpp)
SIM_OPTS = --trace -Wno-lint -Wno-style -Wno-TIMESCALEMOD
TEST = addi
TESTFILE = meminit.bin
PWD = $(shell pwd)
SIM = obj_dir/VminiRV_SoC
RUN_LOG = .run.log

all: build

$(SIM): $(VSRC) $(CSRC)
	@verilator -cc --exe --build $(VSRC) --top-module miniRV_SoC $(CSRC) $(SIM_OPTS) +define+PATH=$(TESTFILE) -CFLAGS -DPATH=$(TESTFILE) -I$(CPU_DIR) -I$(SOC_DIR) -CFLAGS -I$(PWD)/golden_model/include
	@mkdir -p waveform

build: $(SIM)

run: $(SIM)
	@ln -sf bin/$(TEST).bin $(TESTFILE)
	@./obj_dir/VminiRV_SoC $(TEST) > $(RUN_LOG) 2>&1; \
	status=$$?; \
	cat $(RUN_LOG); \
	if [ $$status -ne 0 ] || grep -q "Timed out!" $(RUN_LOG); then \
		rm -f $(RUN_LOG) $(TESTFILE); \
		exit 1; \
	fi; \
	rm -f $(RUN_LOG) $(TESTFILE)

run_for_python: $(SIM)
	@ln -sf bin/$(TEST).bin $(TESTFILE)
	@./obj_dir/VminiRV_SoC $(TEST) > $(RUN_LOG) 2>&1; \
	status=$$?; \
	cat $(RUN_LOG); \
	if [ $$status -ne 0 ] || grep -q "Timed out!" $(RUN_LOG); then \
		rm -f $(RUN_LOG) $(TESTFILE); \
		exit 1; \
	fi; \
	rm -f $(RUN_LOG) $(TESTFILE)

$(TESTFILE):
	ln -sf bin/$(TEST).bin $(TESTFILE)
clean:
	rm -rf obj_dir waveform $(TESTFILE) $(RUN_LOG)

.PHONY: all build run run_for_python clean
