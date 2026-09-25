# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/kern/sysproc.S
#
# Description:
# Process specific system calls
#
# Author: Daniil Dunaeff (dan7)

.include "riscv.inc"

.section .text
.global sys_exit

# Exit system call
sys_exit: # a0 = stackframe address; modified: t0, t1
    svra # save return address
    push a0 # save original argument registers
    push a1
    push a2
    push a0 # save affected register
    la a0, sys_exit_msg
    call printraw # notify about sys_exit
    pop a0 # restore affected register
    ld a0, 80(a0) # load exit status from stackframe
    la a1, sys_itoa_buff # itoa ASCII buffer
    li a2, 10 # decimal base
    call itoa # convert integer to ASCII string
    mv a0, a1 # move ASCII buffer as argument to print function
    call printraw # print exit status
    li a0, '\n' # load newline symbol
    call putc # print newline
    pop a2 # restore original argument registers
    pop a1
    pop a0
    ldra # restore return address
    ret

.section .bss

sys_itoa_buff:
    .fill 16, 1, 0

.section .rodata

sys_exit_msg:
    .asciz "SYS_exit invoked with exit status: "
