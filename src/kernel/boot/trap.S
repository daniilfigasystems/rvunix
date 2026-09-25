# SPDX-License-Identifier: GPL-3.0-or-later

.include "riscv.inc"

.section .text
.global mtrap_init

# Initialize traps
mtrap_init: # no arguments; modified: t0, t1, mtvec
    la t0, trap_handler
    csrw mtvec, t0 # install trap handler to mtvec (machine trap vector)
    li t0, 0xFDFF
    csrw medeleg, t0 # redirect all processor interrupts to supervisor
    li t0, 0x222
    csrw mideleg, t0 # redirect timer, external interrupts to supervisor
    li t0, 2
    csrs mcounteren, t0 # enable rdtime instruction in supervisor
    li t0, 0x8000000000000000
    csrs menvcfg, t0 # enable stimecmp in supervisor
    ret

# Trap handler
trap_handler: # no arguments; modified: t0, t1, mepc
    csrr t0, mstatus # load machine status register
    slli t0, t0, 11
    andi t0, t0, 0x03 # MPP bits
    li t1, 1
    bne t0, t1, trap_panic # if previous mode isn't supervisor then panic
    csrr t0, mepc # load machine exception pc
    nextinst t0 # adjust exception pc to next instruction
    csrw mepc, t0 # store machine exception pc
    mret

# Trap panic
trap_panic: # no arguments; modified: a0, t0
    la a0, trap_trip_msg
    callr panic # trap panic, should not return
    j . # if returned, halt

.section .rodata

trap_trip_msg:
    .asciz "machine mode exception\n"
