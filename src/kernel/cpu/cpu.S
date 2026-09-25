# SPDX-License-Identifier: GPL-3.0-or-later

.include "riscv.inc"

.section .text
.global cpu_enable_sirqs
.global cpu_disable_sirqs
.global cpu_enable_irq
.global cpu_halt

# Enable supervisor interrupts
cpu_enable_sirqs: # no arguments; modified: t0
    svra # save return address
    li t0, 0x02
    csrs sstatus, t0 # enable SIE bit (Supervisor Interrupt Enable) of suprevisor status
    ldra # restore return address
    ret

# Disable supervisor interrupts
cpu_disable_sirqs: # no arguments; modified: t0
    svra # save return address
    li t0, 0x02
    csrc sstatus, t0 # disable SIE bit (Supervisor Interrupt Enable) of suprevisor status
    ldra # restore return address
    ret

# Enable interrupt
cpu_enable_irq:

# Halt processor
cpu_halt: # no arguments; modified: none
    wfi # wait for interrupt
    j . # infinitely jump
