# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/include/vm.inc
#
# Description:
# Virtual memory specific defintions
#
# Author: Daniil Dunaeff (dan7)

# Definitions

# Virtual address to bits (sv39 profile)
# Reserved [63:39]   - Reserved
# VPN[2] [38:30]     - Index for root page table
# VPN[1] [29:21]     - Index for level 1 page table
# VPN[0] [20:12]     - Index for level 0 page table
# Page Offset [11:0] - Offset into the 4k physical page

# Permission flags
.set PTE_V, 0x01 # available page
.set PTE_R, 0x02 # read access
.set PTE_W, 0x04 # write access
.set PTE_X, 0x08 # memory is executable
.set PTE_U, 0x10 # memory is accessible in user mode
.set PTE_G, 0x20 # global mapping (reduces flushing)
.set PTE_A, 0x40 # page was accessed
.set PTE_D, 0x80 # dirty page
.set PTE_V_BIT, 0 # available page
.set PTE_R_BIT, 1 # read access
.set PTE_W_BIT, 2 # write access
.set PTE_X_BIT, 3 # memory is executable
.set PTE_U_BIT, 4 # memory is accessible in user mode
.set PTE_G_BIT, 5 # global mapping (reduces flushing)
.set PTE_A_BIT, 6 # page was accessed
.set PTE_D_BIT, 7 # dirty page

# Default permissions for sections
# Default kernel text mapping
.set PTE_KERNEL_TEXT, (PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D) # PTE_V | PTE_R | PTE_W | PTE_X | PTE_A; read/write, executable memory
# Default kernel data mapping
.set PTE_KERNEL_DATA, (PTE_V | PTE_R | PTE_W | PTE_A | PTE_D) # PTE_V | PTE_R | PTE_W | PTE_A; read/write memory
# Default kernel rodata mapping
.set PTE_KERNEL_RODATA, 0x02 # PTE_R; read only memory
# Default user text mapping
.set PTE_USER_TEXT, (PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_A | PTE_D) # PTE_V | PTE_R | PTE_W | PTE_X | PTE_A; read/write, user, executable memory

# MMU modes
.set MMU_MODE_SV39, 0x08 # Sv39 mode
.set MMU_MODE_SV48, 0x08 # Sv48 mode

# Functions

# Convert physical address to page table entry and store result in destination register
.macro pa2pte destreg, pa
    srli \destreg, \pa, 12 # shift physical address by 12 (page size)
    slli \destreg, \destreg, 10 # shift physical address by 10 (permission bits)
.endm

# Convert page table entry to physical address and store result in destination register
.macro pte2pa destreg, pte
    srli \destreg, \pte, 10 # shift page table entry by 10 (permission bits)
    slli \destreg, \destreg, 12 # shift page table entry by 12 (page size)
.endm

# Get index of page table entry from virtual address and page table level and store result in destination register (immediate)
.macro ptni destreg, va, level
    push t5
    push t6
    mv \destreg, \va
    li t6, 9
    li t5, \level
    mul t6, t6, t5 # calculate page table level
    addi t6, t6, 12 # page offset
    srl \destreg, \destreg, t6 # shift virtual address by 12 (page offset) plus 9 bits multiplied by page table level
    andi \destreg, \destreg, 0x1FF # filter 9 bits (page table index)
    pop t6
    pop t5
.endm

# Get index of page table entry from virtual address and page table level and store result in destination register
.macro ptn destreg, va, level
    push t6
    mv \destreg, \va
    li t6, 9
    mul t6, t6, \level # calculate page table level
    addi t6, t6, 12 # page offset
    srl \destreg, \destreg, t6 # shift virtual address by t6 (page offset) plus 9 bits multiplied by page table level
    andi \destreg, \destreg, 0x1FF # filter 9 bits (page table index)
    pop t6
.endm

# Make satp formatted values
.macro mksatp destreg, pgtbl, format
    push t5
    push t6
    li t5, \format
    slli t5, t5, 60 # set MMU mode
    srli t6, \pgtbl, 12 # convert page table address to PPN
    clr \destreg # clear destination register
    or \destreg, t6, t5 # combine MMU mode and PPN of page table
    pop t5
    pop t6
.endm
