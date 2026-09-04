# RISC-V Workbench 32 & 64

A hands-on RISC-V development and simulation environment for experimenting with RISC-V assembly language and computer architecture.

The repository contains experiments targeting both **RV32** and **RV64**, using the RISC-V GNU toolchain, Spike ISA simulator, and RISC-V Proxy Kernel (`pk`).

The aim is to make the underlying architecture visible rather than hide it behind a high-level language.

## Where RISC-V Is Used

RISC-V is an open instruction-set architecture used across a wide range of applications.

Its strongest adoption is in embedded systems, microcontrollers, SoCs, storage controllers, networking, automotive systems, and specialised hardware. It is also increasingly used as a control processor alongside AI and other hardware accelerators.

RISC-V is particularly attractive for custom silicon because the ISA is open and can be implemented, extended, and integrated without licensing a proprietary CPU architecture.

Commercial and open implementations include processors and cores from companies such as SiFive, Andes Technology, Alibaba, Espressif, StarFive, and others. RISC-V is also increasingly appearing in development boards and Linux-capable systems.

It is not currently a major desktop or smartphone CPU architecture compared with x86 and ARM. Its significance is instead that it provides an open ISA that hardware designers can use from small embedded controllers through to specialised and high-performance processors.

This makes RISC-V particularly useful for studying computer architecture: the ISA can be examined directly, simulated, implemented in hardware, and extended without treating the processor as a proprietary black box.

## Requirements

The following tools are required:

* RISC-V GNU Toolchain
* Spike RISC-V ISA Simulator
* RISC-V Proxy Kernel (`pk`)
* `make` and standard Unix development tools

The GNU toolchain should provide multilib support so that the same compiler can generate both RV32 and RV64 programs.

Check the installation with:

```bash
riscv64-unknown-elf-gcc --version
spike --help
```

The RV32 and RV64 versions of `pk` are separate binaries.

Set their locations in your shell environment:

```bash
export RV32_PK=/path/to/riscv32-unknown-elf/bin/pk
export RV64_PK=/path/to/riscv64-unknown-elf/bin/pk
```

## RV32

The current RV32 experiments use:

```text
Architecture: rv32i_zicsr_zifencei
ABI:          ilp32
```

Example:

```bash
riscv64-unknown-elf-gcc \
    -march=rv32i_zicsr_zifencei \
    -mabi=ilp32 \
    -nostdlib \
    -nostartfiles \
    -static \
    -o hello32 hello.S
```

Run:

```bash
spike --isa=RV32I "$RV32_PK" ./hello32
```

Expected output:

```text
Hello, RISC-V RV32!
```

## RV64

The current RV64 experiments use:

```text
Architecture: rv64imafdc_zifencei
ABI:          lp64d
```

Example:

```bash
riscv64-unknown-elf-gcc \
    -march=rv64imafdc_zifencei \
    -mabi=lp64d \
    -nostdlib \
    -nostartfiles \
    -static \
    -o hello64 hello64.S
```

Run:

```bash
spike "$RV64_PK" ./hello64
```

Expected output:

```text
Hello, RISC-V RV64!
```

## Compile Flags

The examples deliberately use a minimal set of compiler and linker options so that the resulting programs have as little runtime machinery as possible.

### `-march`

Specifies the RISC-V instruction-set architecture to generate.

For RV32:

```text
-march=rv32i_zicsr_zifencei
```

This selects:

* `rv32` — 32-bit RISC-V base architecture
* `i` — integer instruction set
* `zicsr` — CSR instructions
* `zifencei` — instruction-fetch fence instruction

For RV64:

```text
-march=rv64imafdc_zifencei
```

This selects:

* `rv64` — 64-bit RISC-V base architecture
* `i` — integer instruction set
* `m` — integer multiplication and division
* `a` — atomic instructions
* `f` — single-precision floating point
* `d` — double-precision floating point
* `c` — compressed instructions
* `zicsr` — CSR instructions
* `zifencei` — instruction-fetch fence instruction

The `-march` option therefore determines which instructions the compiler and assembler are permitted to generate.

### `-mabi`

Selects the application binary interface used by the generated code.

RV32:

```text
-mabi=ilp32
```

RV64:

```text
-mabi=lp64d
```

The names describe the sizes of the C-language fundamental integer and pointer types used by the ABI:

* `i` — `int` is 32 bits
* `l` — `long` is 32 bits in `ilp32`, 64 bits in `lp64`
* `p` — pointers are 32 bits in `ilp32`
* `d` — the ABI uses the hardware double-precision floating-point registers

Even though these examples are written in assembly, the ABI still determines conventions such as register usage, argument passing and system-call interfaces.

### `-nostdlib`

Do not link the standard system libraries or startup code.

This prevents the linker from automatically adding things such as:

* libc
* startup routines
* standard system libraries

The program therefore has to provide its own entry point and perform its own system interactions.

### `-nostartfiles`

Do not link the standard C runtime startup files.

Normally a C program would have startup code which eventually calls `main()`. These assembly programs provide `_start` themselves, so that machinery is unnecessary.

`-nostartfiles` is somewhat redundant when `-nostdlib` is already specified, but it makes the intention explicit.

### `-static`

Produce a statically linked executable.

There is no dynamic linker or runtime shared-library dependency. This is appropriate for programs being executed by `pk`, which expects statically linked RISC-V application binaries.

### `-o`

Specifies the name of the output executable:

```text
-o hello32
```

or:

```text
-o hello64
```

### Putting It Together

For example:

```bash
riscv64-unknown-elf-gcc \
    -march=rv32i_zicsr_zifencei \
    -mabi=ilp32 \
    -nostdlib \
    -nostartfiles \
    -static \
    -o hello32 hello.S
```

can be read as:

```text
Use the RISC-V cross compiler
        ↓
Generate RV32I code
        ↓
Use the ILP32 ABI
        ↓
Don't provide standard libraries
        ↓
Don't provide standard startup code
        ↓
Link statically
        ↓
Produce the executable hello32
```

This keeps the resulting executable close to the actual RISC-V program being studied.

## Assembly and System Calls

The examples use `_start` as the program entry point rather than `main`.

For example:

```asm
.globl _start

_start:
    li   a0, 1
    la   a1, msg
    li   a2, 19
    li   a7, 64
    ecall
```

The `ecall` instruction transfers control to the execution environment. When running under `pk`, the proxy kernel handles the system call and provides the requested host functionality.

This makes it possible to write small programs entirely in RISC-V assembly while still having access to basic I/O.

## Inspecting the Generated Code

The RISC-V binutils can be used to examine the resulting ELF files and machine code.

For example:

```bash
riscv64-unknown-elf-readelf -h hello32
```

and:

```bash
riscv64-unknown-elf-objdump -d hello32
```

The same tools can be used for RV64 binaries.

## Why RV32 and RV64?

Having both targets available makes it possible to directly compare the two architectures while studying:

* registers and register width
* integer arithmetic
* immediates
* loads and stores
* addressing
* pointers
* calling conventions
* ABIs
* instruction encoding
* memory layout
* system calls
* ELF binaries
* privileged execution

## Repository Structure

The repository will grow as experiments are added. The general structure is:

```text
.
├── README.md
├── .gitignore
├── rv32/
├── rv64/
└── notes/
```

The exact organisation may change as the experiments develop.

Generated binaries and build artefacts are not committed.

## Approach

The goal is to work from the architecture upward:

```text
RISC-V source
     ↓
assembler / compiler
     ↓
ELF executable
     ↓
machine instructions
     ↓
Spike
     ↓
RISC-V execution
```

The intention is to be able to inspect each stage rather than treating the compiler and simulator as a black box.

## Status

Early stage.

Both RV32 and RV64 environments are operational, including assembly programs capable of producing host-visible output through the RISC-V Proxy Kernel.

More experiments will be added as the architecture is explored.

