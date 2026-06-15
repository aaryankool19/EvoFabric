SIM ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave
BUILD_DIR := build

INCLUDES := -Irtl/accelerators
SVFLAGS := -g2012 -Wall $(INCLUDES)

RTL := \
	rtl/accelerators/popcount_accel.sv \
	rtl/accelerators/crc32_accel.sv \
	rtl/accelerators/fir_filter_accel.sv \
	rtl/accelerators/matmul2x2_accel.sv \
	rtl/soc/virtual_reconfig_slot.sv \
	rtl/control/adaptive_controller.sv \
	rtl/control/accel_safety_checker.sv \
	rtl/monitors/performance_counters.sv \
	rtl/interconnect/mmio_bus.sv \
	rtl/core/rv32i_placeholder.sv \
	rtl/soc/instruction_memory.sv \
	rtl/soc/data_memory.sv \
	rtl/soc/evofabric_top.sv

TESTS := \
	tb_popcount_accel \
	tb_crc32_accel \
	tb_fir_filter_accel \
	tb_matmul2x2_accel \
	tb_accelerator_interface \
	tb_adaptive_controller \
	tb_safety_checker \
	tb_top_workload_switching \
	tb_bad_result_fallback

.PHONY: all test clean waves list

all: test

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%: tb/%.sv $(RTL) | $(BUILD_DIR)
	$(SIM) $(SVFLAGS) -s $* -o $@ $< $(RTL)

test: $(addprefix $(BUILD_DIR)/,$(TESTS))
	@set -e; for test in $(TESTS); do echo "Running $$test"; $(VVP) $(BUILD_DIR)/$$test; done

waves:
	@ls $(BUILD_DIR)/*.vcd
	@echo "Open a VCD with: $(GTKWAVE) build/<test>.vcd"

list:
	@printf '%s\n' $(TESTS)

clean:
	rm -rf $(BUILD_DIR)
