# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/include/memlayout.inc
#
# Description:
# Memory layout
#
# Author: Daniil Dunaeff (dan7)

# Definitions

.set MM_UART_IO, 0x10000000 # UART base address 
.set MM_KERN_BASE, 0x80000000 # kernel loaded at that address
.set MM_MEM_SIZE, (64 * 1024 * 1024) # physical memory size
.set MM_PHYSTOP, (MM_KERN_BASE + MM_MEM_SIZE) # physical memory stop
