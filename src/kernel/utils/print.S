.include "riscv.inc"

.section .text
.global printraw
.global panic

# print raw string
printraw: # a0 = string address; modified: t0
    push a0 # save original argument registers
_printraw_loop:
    lb t0, 0(a0) # load character from string
    addi a0, a0, 1 # increment pointer to string
    push a0 # save affected registers
    push t0
    mv a0, t0
    callr uart_write # write character to terminal
    pop t0 # restore registers
    pop a0
    bnez t0, _printraw_loop # loop until terminal character
_printraw_end:
    pop a0 # restore original argument registers
    ret

# panic and halt system
panic: # a0 = panic message; modified: t0
    callr printraw
    j .
