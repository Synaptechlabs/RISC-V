RISC-V / Spike Quick Reference
Toolchain

Check installed tools:

which riscv64-unknown-elf-gcc
which riscv64-unknown-elf-objdump
which riscv64-unknown-elf-readelf
which spike

Versions:

riscv64-unknown-elf-gcc --version
spike --version

Compiler target information:

riscv64-unknown-elf-gcc -v
riscv64-unknown-elf-gcc -print-multi-lib

The compiler is a multilib compiler, so the same GCC installation can generate RV32 and RV64 code.

Assembly → ELF
RV32
riscv64-unknown-elf-gcc \
    -march=rv32i_zicsr_zifencei \
    -mabi=ilp32 \
    -nostdlib \
    -nostartfiles \
    -static \
    -o hello hello.S
RV64
riscv64-unknown-elf-gcc \
    -march=rv64imafdc_zifencei \
    -mabi=lp64d \
    -nostdlib \
    -nostartfiles \
    -static \
    -o hello64 hello64.S

Useful options:

Option	Meaning
-march=	Target ISA/extensions
-mabi=	ABI / register and data model
-nostdlib	Don't link standard libraries
-nostartfiles	Don't use standard startup code
-static	Static executable
-o	Output filename

For an architecture experiment, -nostdlib -nostartfiles is useful because you aren't hiding the interesting stuff behind libc/startup code.

Inspect the ELF
File type
file hello
file hello64
ELF header
riscv64-unknown-elf-readelf -h hello

Particularly useful fields:

Class:       ELF32 / ELF64
Machine:     RISC-V
Entry point: ...
Sections
riscv64-unknown-elf-readelf -S hello
Symbols
riscv64-unknown-elf-readelf -s hello
Program headers / load segments
riscv64-unknown-elf-readelf -l hello
Disassembly

Basic:

riscv64-unknown-elf-objdump -d hello

RV64:

riscv64-unknown-elf-objdump -d hello64
Show actual/non-alias mnemonics
riscv64-unknown-elf-objdump -d -M no-aliases hello64

This is particularly useful for what you're doing.

For example:

4505                 c.li    a0,1
00000597             auipc   a1,0
01c58593             addi    a1,a1,28
04000893             addi    a7,zero,64
00000073             ecall
Include source alongside disassembly

If debug information is present:

riscv64-unknown-elf-objdump -d -S hello
Disassemble everything
riscv64-unknown-elf-objdump -D hello

-d = executable sections.

-D = all sections that can be interpreted as instructions.

Examine raw bytes
riscv64-unknown-elf-objdump -s hello

Or specifically .text:

riscv64-unknown-elf-objdump -s -j .text hello

This is useful when you want to go:

assembly
   ↓
instruction
   ↓
machine encoding
   ↓
individual bit fields
Symbols / addresses
riscv64-unknown-elf-nm hello

For example:

00010074 T _start
00010098 r msg

Useful for seeing where functions/data ended up.

Spike
Run RV64 program
spike \
    /usr/local/Cellar/riscv-pk/main/riscv64-unknown-elf/bin/pk \
    ./hello64

Or define:

export RV64_PK=/path/to/riscv64-unknown-elf/bin/pk

then:

spike "$RV64_PK" ./hello64
Run RV32
spike --isa=RV32I \
    "$RV32_PK" \
    ./hello

where:

export RV32_PK=/path/to/riscv32-unknown-elf/bin/pk
Spike without pk

For bare-metal code:

spike --isa=RV32I ./baremetal

or RV64:

spike ./baremetal64

Here Spike is essentially just providing the simulated RISC-V machine.

There is no operating system and therefore no Linux syscall environment.

Spike debugging

Spike has a useful interactive/debug mode.

Start with:

spike -d ./baremetal

You can also use:

spike --isa=RV32I -d ./baremetal

This drops into Spike's debug interface.

Useful commands include:

r

show registers.

pc

show program counter.

reg 0

inspect register state.

:until pc 0x80001000

run until a particular PC.

q

quit.

The exact debugger command set is worth checking with:

help

once inside the debugger.

GDB

For more serious debugging, the interesting combination is:

GDB
 │
 ▼
Spike
 │
 ▼
RISC-V program

Start Spike with a remote debugging port:

spike --rbb-port=9824 ./baremetal

Then in another terminal:

riscv64-unknown-elf-gdb ./baremetal

Inside GDB:

target remote :9824

Then the normal GDB machinery becomes available:

info registers
x/i $pc
display/i $pc
si

(single instruction)

ni

(next instruction)

break _start
continue
disassemble _start
x/10wx 0x80001000

This is where things become considerably more interesting because you can watch:

PC
 ↓
instruction
 ↓
register changes
 ↓
memory changes

instruction by instruction.

Useful experiments
Remove compressed instructions

Compile RV64 without C:

riscv64-unknown-elf-gcc \
    -march=rv64ima_zicsr_zifencei \
    -mabi=lp64 \
    -nostdlib \
    -nostartfiles \
    -static \
    -o hello64-noc hello64.S

Then:

riscv64-unknown-elf-objdump -d -M no-aliases hello64-noc

Compare with:

riscv64-unknown-elf-objdump -d -M no-aliases hello64

You'll see the effect of the C extension directly in the instruction stream.

See what li actually becomes

Write:

li a0, 1

compile and disassemble:

riscv64-unknown-elf-objdump -d -M no-aliases hello64

Then replace it manually with the underlying instruction where appropriate:

addi a0, zero, 1

and compare.

For larger constants, li becomes more interesting because it can expand into multiple instructions.

See what la does

Source:

la a1, msg

Disassembly:

auipc a1,...
addi  a1,a1,...

This is a particularly good experiment because it introduces:

PC-relative addressing
relocations
linker resolution
instruction encoding

rather than just register arithmetic.

The overall workflow

The useful mental model for your lab is:

             hello.S
                │
                │ GCC / assembler
                ▼
              hello
                │
        ┌───────┴────────┐
        │                │
     readelf          objdump
        │                │
      ELF          instructions
     structure       / encodings
        │                │
        └───────┬────────┘
                │
              Spike
                │
          simulated CPU
                │
        ┌───────┴────────┐
        │                │
       pk             bare metal
        │
      ecall
        │
    host OS I/O
