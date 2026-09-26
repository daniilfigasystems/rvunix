# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/kern/proc.S
#
# Description:
# Process management
#
# Author: Daniil Dunaeff (dan7)

.include "riscv.inc"
.include "proc.inc"
.include "vm.inc"
.include "limits.inc"
.include "errno.inc"

.section .text
.global proc_palloc
.global proc_create
.global proc_init

# Allocate process identifier
proc_palloc: # no arguments; modified: t0, t1, a0 (returns allocated process identifier or an error)
    svra # save return address
    la t0, last_pid # load last process identifier address
    ld a0, 0(t0) # load last process identifier value from last process identifier
    li t1, MAX_PROC # load max process count immediate
    bge a0, t1, _proc_alloc_err # if we hit process identifier count limit, return an error
    inc a0 # increment last process identifier
    sd a0, 0(t0) # store modified last process identifier
_proc_palloc_end:
    ldra # restore return address
    ret
_proc_palloc_err:
    li a0, -EAGAIN # return EAGAIN error code
    j _proc_alloc_end # jump to end

# Create new process
proc_create: # no arguments; modified: t0, t1, t2, a0 (returns process structure here)
    svra # save return address
    call proc_palloc # allocate process identifier for new process
    bltz a0, _proc_create_err # if function returned an error, return an error
    # TODO
_proc_create_end:
    ldra # restore return address
    ret
_proc_create_err:
    li a0, -EAGAIN # return EAGAIN error code
    j _proc_create_end # jump to end

# Initialize process manager
proc_init: # no arguments; modified: t0, t1, t2, t3
# TODO

.section .bss

# ==============================================================================
# Process structure definition
# Total size: 118 bytes (assuming 8 byte (uint64) alignment for RV64)
# ==============================================================================
# Offset  | Size (B) | Field description
# --------|----------|---------------------------------------------------------
# 0       | 8        | trapframe   - address of trapframe structure
# 8       | 8        | procstate   - process state
# 16      | 8        | chan        - channel (reserved for now)
# 24      | 8        | killed      - killed
# 32      | 8        | exstatus    - exit status
# 40      | 8        | pid         - process identifier
# 48      | 8        | parent      - address of parent process structure
# 56      | 8        | kstack      - virtual address of kernel stack
# 64      | 8        | size        - size of process memory (B)
# 72      | 8        | pgtable     - user page table
# 80      | 8        | ctx         - context
# 88      | 8        | ofile       - address of array containing addresses of opened file structures
# 96      | 8        | cwd         - current directory
# 102     | 8        | name        - address of process name string
# 110     | 8        | mode        - current mode of process (0 for native, 1 for rvdos emulation) (reserved for now)
# ==============================================================================
procs:
    .fill 118 * MAX_PROC, 1, 0

last_pid:
    .quad 0x0000000000000000 # last process identifier