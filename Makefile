############
# Sim type #
############

# Define simulator we are using, priority to iverilog
SIM ?= verilator

###########
# Globals #
###########

# Global configs.
FPGA_DIR := fpga
CONF := conf
DEBUG_FLAG := $(if $(debug), debug=1)
DEFINES := $(if $(wave),wave=1)
WAIVER_FILE := waiver.vlt
SRC_DIR:= src
SRC_10GBASE_R := $(SRC_DIR)/10GBASE-R


# Lint #
########

# Lint variables.
LINT_FLAGS :=
ifeq ($(SIM),icarus)
LINT_FLAGS +=-Wall -g2012 $(if $(assert),-gassertions) -gstrict-expr-width
LINT_FLAGS +=$(if $(debug),-DDEBUG) 
else
LINT_FLAGS += -Wall 
LINT_FLAGS += -Wno-DECLFILENAME
LINT_FLAGS +=$(if $(wip),-Wno-UNUSEDSIGNAL)
LINT_FLAGS += -Ilib
endif

# Lint commands.
ifeq ($(SIM),icarus)
define LINT
	mkdir -p build
	iverilog $(LINT_FLAGS) -s $2 -o $(BUILD_DIR)/$2 $1
endef
else
	
define LINT
	mkdir -p build
	verilator $(CONF)/$(WAIVER_FILE) --lint-only $(LINT_FLAGS) --no-timing $1 --top $2
endef
endif

########
# Lint #
########

10g_deps := $(wildcard $(SRC_10GBASE_R)/*.v) 

lint_10g_tx: $(10g_deps)
	$(call LINT,$^, xgmii_pcs_10g_tx)

.PHONY: lint_10g_tx

#############
# Testbench #
#############
# Call cocotb
test:
	COCOTB_LOG_LEVEL=$(if $(debug),DEBUG,INFO) $(MAKE) -C $(TB_DIR) $(if $(wave),WAVES=1) 

test_gates: gates
	COCOTB_LOG_LEVEL=$(if $(debug),DEBUG,INFO) GATES=yes $(MAKE) -C $(TB_DIR) $(if $(wave),WAVES=1) 

waves: 
	gtkwave $(TB_DIR)/tb.vcd $(CONF)/tb.gtkw &

