# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/cpu/cpu.S
#
# Description:
# Processor related functions
#
# Author: Daniil Dunaeff (dan7)

.include "riscv.inc"

.section .text
.global cpu_enable_sirqs
.global cpu_disable_sirqs
.global cpu_enable_irq
.global cpu_disable_irq
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
cpu_enable_irq: # a0 = interrupt number; modified: t0
    svra # save return address
    csrr t0, sie # read supervisor interrupt enable register
    bset t0, a0 # set bit of specified irq to enable it
    csrw sie, t0 # write modified supervisor interrupt enable register back
    ldra # restore return address
    ret

# Disable interrupt
cpu_disable_irq: # a0 = interrupt number; modified: t0
    svra # save return address
    csrr t0, sie # read supervisor interrupt enable register
    bclr t0, a0 # clear bit of specified irq to disable it
    csrw sie, t0 # write modified supervisor interrupt enable register back
    ldra # restore return address
    ret

# Halt processor
cpu_halt: # no arguments; modified: none
    wfi # wait for interrupt
    j . # infinitely jump
