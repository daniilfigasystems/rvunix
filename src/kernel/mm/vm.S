.include "riscv.inc"
.include "memlayout.inc"
.include "vm.inc"

.section .text
.global kernel_pagedir
.global walk
.global walk_addr
.global map_pages
.global map_pagess
.global vm_init

# Walk through page table entries and return last page table entry translated from virtual address
walk: # a0 = ptbl, a1 = va, a2 = alloc; modified: t0, t1, t2, t3, a0 (returns pte0 here)
    svra # save return address
    li t0, 2 # 3 levels of page table (from 2 to 1)
    mv t1, a0 # page table address
_walk_loop:
    ptn t2, a1, t0 # extract PPN bits from virtual address
    li t3, 8
    mul t3, t2, t3 # obtain index of page table by multiplying PPN by 8 (uint64)
    add t3, t1, t3 # switch to that address 
    ld t1, 0(t3) # load PTE from page table index
    beqz t0, _walk_exit # if reached last page level, extract final physical address and exit
    btsti t2, t1, PTE_V_BIT # check if PTE exists
    beqz t2, _walk_alloc # if PTE doesn't exist, allocate it
    pte2pa t1, t1 # convert PTE to physical address
_walk_continue:
    dec t0 # switch to next level of page table
    j _walk_loop
_walk_alloc:
    beqz a2, _walk_panic # if allocate flag not set, panic
    push a0 # save affected registers
    push t0
    call kalloc # allocate PTE
    pa2pte t0, a0 # convert allocated physical address to PTE
    bseti t0, PTE_V_BIT # mark PTE as existing
    sd t0, 0(t3) # store PTE at PTE address
    mv t1, a0 # set page table address to new PTE
    pop t0 # restore registers
    pop a0
    j _walk_continue # continue loop
_walk_panic:
    la a0, nonexistent_page_msg
    call panic # panic if PTE entry doesn't exist and allocate flag is not set
_walk_exit:
    mv a0, t3 # return pte0
    ldra # restore return address
    ret

# Translate virtual address into physical address
walk_addr: # a0 = pgtbl (returns pa here), a1 = va; modified: t0, t1, t2, t3
    svra # save return address
    push a1 # save original argument registers
    push a2
    clr a2 # do not allocate memory, just walk through page table
    call walk # get last page table entry address from page table and virtual address
    ld a0, 0(a0) # load page table entry from page table entry address
    pte2pa a0, a0 # convert last page table entry into physical address
    li t0, PAGE_SIZE
    and a1, a1, t0 # get first 12 bits of virtual address (offset to physical address)
    or a0, a0, a1 # combine physical address and offset together
    pop a2 # restore original argument registers
    pop a1
    ldra # restore return address
    ret

# Map pages to virtual address
map_pages: # a0 = pgtbl, a1 = pa, a2 = va, a3 = prot, a4 = n; modified: t0, t1, t2, t3
    svra # save return address
    push a1 # save original argument registers
    push a2
    push a4
    pgalignup a1, a1 # page align physical address
    pgalignup a2, a2 # page align virtual address
_map_pages_loop:
    push a0 # save affected registers
    push a1
    push a2
    mv a1, a2
    li a2, 1 # allocate page table entry while walking
    call walk # get last page table entry from virtual address
    mv t0, a0
    pop a2 # restore registers
    pop a1
    pop a0
    pa2pte t1, a1 # convert physical address into page table entry
    or t1, t1, a3 # apply protection bits
    sd t1, 0(t0) # store prepared page table entry to page table entry address
    li t1, PAGE_SIZE
    add a1, a1, t1 # switch to next page
    add a2, a2, t1
    dec a4 # decrement counter
    bnez a4, _map_pages_loop # loop until last page
_map_pages_end:
    pop a4 # restore original argument registers
    pop a2
    pop a1
    ldra # restore return address
    ret

# Map pages simple
map_pagess: # a0 = pgtbl, a1 = pa, a2 = va, a3 = prot, a4 = size; modified: t0, t1, t2, t3
    svra # save return address
    push a4 # save original argument registers
    li t0, PAGE_SIZE
    pgalignup a4, a4 # page align size
    divu a4, a4, t0 # divide size by page size (convert to pages)
    call map_pages # call verbose map pages
    pop a4 # restore original argument registers
    ldra # restore return address
    ret

# Initialize virtual memory
vm_init: # no arguments; modified: t0, t1, t2, t3
    svra # save return address
    push a0 # save original argument registers
    push a1
    push a2
    push a3
    push a4
    la a0, kernel_pagedir # kernel page directory will be filled with pte entries
    li a1, MM_KERN_BASE # start mapping at kernel base address
    li a2, MM_KERN_BASE # map kernel at same virtual address
    li a3, PTE_KERNEL_TEXT # default mapping of kernel text
    li a4, MM_PHYSTOP
    sub a4, a4, a2 # map whole memory
    call map_pagess # map pages of kernel
    li a1, MM_UART_IO # now map UART MMIO
    li a2, MM_UART_IO # map UART MMIO at same virtual address
    li a3, PTE_KERNEL_DATA # make it read/write mapping
    li a4, PAGE_SIZE # map whole page of UART MMIO
    call map_pagess # map pages of UART MMIO
    la a0, kernel_pagedir # kernel page directory address
    mksatp t0, a0, MMU_MODE_SV39 # create formatted SATP register
    csrw satp, t0 # install formatted SATP register
    sfence.vma # clear TLB cache
    pop a4 # restore original argument registers
    pop a3
    pop a2
    pop a1
    pop a0
    ldra # restore return address
    ret

.section .bss

kernel_pagedir:
    .quad 0x0000000000000000 # kernel page directory address

.section .rodata

nonexistent_page_msg:
    .asciz "walk: page does not exist!\n"
