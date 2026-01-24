.include "riscv.inc"

.section .text
.global trap_init

# initialize traps
trap_init: # no arguments; modified: t0, t1, mtvec
    ret

# trap handler
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

# trap panic
trap_panic: # no arguments; modified: a0
    la a0, trap_trip_msg
    callr panic # trap panic, should not return
    j . # if returned, halt

.section .data

trap_trip_msg:
    .asciz "trap trip\n"
