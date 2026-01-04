SV_FILES = ${wildcard ./src/pkg/*.sv} ${wildcard ./src/*.sv}
TB_FILES = ${wildcard ./tb/*.sv}
ALL_FILES = ${SV_FILES} ${TB_FILES}

CROSS_COMPILE = riscv64-unknown-elf-
CC      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
CFLAGS  = -march=rv32i -mabi=ilp32 -Ttext 0x80000000 -nostdlib -O1

lint:
	@echo "Running lint checks..."
	verilator --lint-only -Wall --timing -Wno-CASEINCOMPLETE ${ALL_FILES}

firmware:
	@echo "C kodu derleniyor..."
	$(CC) $(CFLAGS) ./firmware/main.c -o ./firmware/main.elf
	$(OBJCOPY) -O verilog --change-addresses -0x80000000 ./firmware/main.elf ./test/bare_metal.hex
	@echo "Hex formatting..."
	@python3 ./firmware/fix_hex.py
	@echo "Hex file is done!"

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
	rm -f ./firmware/main.elf

.PHONY: compile run wave lint clean help firmware