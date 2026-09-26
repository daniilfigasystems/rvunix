# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/kern/proc.S
#
# Description:
# Process management
#
# Author: Daniil Dunaeff (dan7)

.include "riscv.inc"
.include "vm.inc"
.include "limits.inc"
.include "errno.inc"

.section .text
.global proc_init

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
