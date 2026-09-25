# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/utils/print.S
#
# Description:
# Debug printing functionality
#
# Author: Daniil Dunaeff (dan7)

.include "riscv.inc"

.section .text
.global putc
.global printraw
.global panic

# print one character
putc: # a0 = character to print; modified: t0
    svra # save return address
    call uart_write # write character to terminal through UART driver
    ldra # restore return address
    ret

# print raw string
printraw: # a0 = string address; modified: t0
    svra # save return address
    push a0 # save original argument registers
_printraw_loop:
    lb t0, 0(a0) # load character from string
    addi a0, a0, 1 # increment pointer to string
    push a0 # save affected registers
    push t0
    mv a0, t0
    call putc # write character to terminal
    pop t0 # restore registers
    pop a0
    bnez t0, _printraw_loop # loop until terminal character
_printraw_end:
    pop a0 # restore original argument registers
    ldra # restore return address
    ret

# panic and halt system
panic: # a0 = panic message; modified: t0
    call printraw
    j .
