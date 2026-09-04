.section .text
.globl _start

_start:
    li   a0, 1
    la   a1, msg
    li   a2, 19
    li   a7, 64
    ecall

    li   a0, 0
    li   a7, 93
    ecall

.section .rodata
msg:
    .ascii "Hello, RISC-V RV32!\n"
