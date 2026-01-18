#!/bin/sh

RV_PREFIX=riscv32-unknown-elf
RV_GCCOPTS="-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles"
RV_TESTS_SRCDIR=/opt/riscv-tests
RV_GCCOPTS="$RV_GCCOPTS -I$RV_TESTS_SRCDIR/env/p -I$RV_TESTS_SRCDIR/isa/macros/scalar -T$RV_TESTS_SRCDIR/env/p/link.ld"
RV_GCCOPTS="$RV_GCCOPTS -march=rv32im -mabi=ilp32"
RV_OBJDUMP_OPTS="--disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data"

if [ ! -f $1 ]; then
    echo "File $1 not found"
    exit 1
fi

RESFILE=perf-$(basename $1)
${RV_PREFIX}-gcc $1 $RV_GCCOPTS -o $RESFILE.elf
${RV_PREFIX}-objdump $RV_OBJDUMP_OPTS $RESFILE.elf > $RESFILE.dump
/tmp/elf2hex-1.0.1/target/bin/${RV_PREFIX}-elf2hex --bit-width 32 --input $RESFILE.elf --output $RESFILE.hex