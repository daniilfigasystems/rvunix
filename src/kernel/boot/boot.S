# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/boot/boot.S
#
# Description:
# Early boot and transition to S-mode
#
# Author: Daniil Dunaeff (dan7)

.include "riscv.inc"

.section .text
.global _kentry

_kentry:
    csrw satp, zero # zero out page table
    la gp, _gp_addr # load general pointer
    la sp, _sp_addr # load stack pointer
    csrr x5, mhartid # get core id
    bnez x5, _kloop # if not first core halt
    li t0, 0x1F # configure memory access in supervisor mode
    csrw pmpcfg0, t0 # store physical memory protection configuration register
    li t0, -1 # filter access to all memory
    csrw pmpaddr0, t0 # store physical memory protection filter address register
    csrr t0, mstatus
    li t1, ~((3 << 11) | (1 << 7) | (1 << 3)) # clear bits: MPP, MPIE, MIE (machine interrupt enable)
    and t0, t0, t1 # clear bits of mstatus
    li t1, (1 << 11) | (1 << 7) # set bits: MPP = 1 (S-mode, bit 11), MPIE = 1 (bit 7)
    or t0, t0, t1 # set bits of mstatus
    csrw mstatus, t0 # set register mstatus
    call mtrap_init
    la t0, kmain
    csrw mepc, t0 # set machine exception pc pointing to kernel main function
    mret # now should jump to kmain
_kloop:
    j _kloop # halt other cores
