
hello64:     file format elf64-littleriscv


Disassembly of section .text:

00000000000100b0 <_start>:
   100b0:	4505                	li	a0,1
   100b2:	00000597          	auipc	a1,0x0
   100b6:	01c58593          	addi	a1,a1,28 # 100ce <msg>
   100ba:	464d                	li	a2,19
   100bc:	04000893          	li	a7,64
   100c0:	00000073          	ecall
   100c4:	4501                	li	a0,0
   100c6:	05d00893          	li	a7,93
   100ca:	00000073          	ecall
