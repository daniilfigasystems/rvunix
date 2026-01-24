.include "riscv.inc"

.section .text
.global _kentry

_kentry:
    csrw satp, zero # zero out page table
    la gp, _gp_addr # load general pointer
    la sp, _sp_addr # load stack pointer
    csrr x5, mhartid # get core id
    bnez x5, _kloop # if not first core halt
    li t0, 0xF # configure memory access in supervisor mode
    csrw pmpcfg0, t0 # store physical memory protection configuration register
    li t0, -1 # filter access to all memory
    csrw pmpaddr0, t0 # store physical memory protection filter address register
    bseti t0, 11 # set previous mode to supervisor
    bseti t0, 3 # set machine interrupt enable (MIE)
    csrrs t0, mstatus, t0 # load machine status register and set bits
    bseti t0, 7 # set machine interrupt enable (MPIE)
    csrrs t0, mstatus, t1 # load machine status register and set bits 
    la t0, kmain
    csrw mepc, t0 # set machine exception pc pointing to kernel main function
    mret # now should jump to kmain
_kloop:
    j _kloop # halt other cores
