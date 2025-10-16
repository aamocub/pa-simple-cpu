#!/bin/bash

VERILATORFLAGS="-Wall -Wno-fatal --timing --binary -j 0 --trace-fst --autoflush --assert -I./rtl -I./bench --prof-cfuncs -CFLAGS -DVL_DEBUG"

verilator $VERILATORFLAGS $1