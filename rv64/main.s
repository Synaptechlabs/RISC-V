.text
.align  2

main:
    addi sp,sp,-16
    li a0,10
    sw ra,12(sp)
    jal func
    lw ra,12(sp)
    addi a0,a0,1
    addi sp,sp,16
    ret
