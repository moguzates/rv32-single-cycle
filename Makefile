SV_FILES = ${wildcard ./src/pkg/*.sv} ${wildcard ./src/*.sv}
TB_FILES = ${wildcard ./tb/*.sv}
ALL_FILES = ${SV_FILES} ${TB_FILES}

lint:
	@echo "Running lint checks..."
	verilator --lint-only -Wall --timing -Wno-CASEINCOMPLETE ${ALL_FILES}

build:
	verilator --binary ${SV_FILES} ./tb/tb.sv \
		--top tb -j 0 --trace -Wno-CASEINCOMPLETE \
		-CFLAGS "-std=c++20 -fcoroutines"

run: build
	obj_dir/Vtb

wave: run
	gtkwave --dark dump.vcd

clean:
	@echo "Cleaning temp files..."
	rm -f dump.vcd
	rm -rf obj_dir
	rm -rf ./diff.log
	rm -rf ./model.log

.PHONY: compile run wave lint clean help
