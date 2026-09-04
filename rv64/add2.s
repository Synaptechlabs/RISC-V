# added the an additional character ASCII 10 '\n'

.text
.align 2

_start:
    addi t0, zero, 5       # t0 = 5
    addi t1, zero, 4       # t1 = 4
    add  t2, t0, t1        # t2 = 9

    addi a0, t2, 48        # ASCII '0' + 9 = ASCII '9'
    addi sp, sp, -16

    addi a2, zero, 10    # a2 = ASCII newline = 10
    sb a0, 12(sp)           # store byte
    sb a2, 13(sp)

    addi a0, zero, 1       # stdout
    addi a1, sp, 12        # address of character
    addi a2, zero, 2       # length = 2
    addi a7, zero, 64      # write
    ecall

    addi a0, zero, 0       # exit status
    addi a7, zero, 93      # exit
    ecall
